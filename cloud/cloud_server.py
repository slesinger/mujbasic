"""
C64 HDN Cloud Server Application

TCP server that receives commands from C64 and responds with data.
Can run on local PC or in serverless cloud.
Requires C64 Ultimate with network target on the client side.
"""
import socket
import threading
import logging
import sys
import os
import argparse
from typing import Tuple, Optional, List
from generate_pet_asc_table import Petscii
from base_handler import BaseHandler
from chat_handler import ChatHandler
from help_handler import HelpHandler
from python_eval_handler import PythonEvalHandler
from csdb_handler import CSDBHandler
from shared_state import get_session_state

# Configure logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger(__name__)


# Protocol constants
MAGIC_BYTES = bytes([0xFE, 0xFF])


class CommandID:
    """Command IDs from C64 client"""
    KEYPRESS = 0x01
    TEXT_INPUT = 0x02


class ResponseType:
    """Response types sent to C64"""
    PETSCII_NULL_TERMINATED = 0x01
    MIX_COMMANDS_SCREEN_CODES = 0x02
    MTEXT_FORMAT = 0x03


class ModifierFlags:
    """Modifier flags for keypress commands"""
    SHIFT = 0x01
    CTRL = 0x02
    COMMODORE = 0x04


class RequestDispatcher:
    """Dispatches text input requests to appropriate handlers"""

    def __init__(self):
        """Initialize dispatcher with all available handlers"""
        self.handlers: List[BaseHandler] = []
        self._initialize_handlers()

    def _initialize_handlers(self):
        """Initialize all request handlers in priority order"""
        try:
            # Order matters - first matching handler will process the request
            self.handlers = [
                HelpHandler(),
                PythonEvalHandler(),
                ChatHandler(),
                CSDBHandler(),
            ]
            logger.info(f"Initialized {len(self.handlers)} request handlers")
        except Exception as e:
            logger.error(f"Error initializing handlers: {e}")
            self.handlers = []

    def dispatch(self, petscii_text: bytes, session_id: int = 0) -> bytes:
        """
        Dispatch request to appropriate handler

        Args:
            petscii_text: PETSCII encoded text input (null-terminated)
            session_id: The session ID for the request

        Returns:
            PETSCII encoded response
        """
        try:
            # Convert PETSCII to UTF-8
            utf8_text = BaseHandler.petscii_to_utf8(petscii_text.rstrip(b'\x00'))
            logger.info(f"Session {session_id}: Received: '{utf8_text}'")

            # Find appropriate handler
            for handler in self.handlers:
                if handler.can_handle(utf8_text, session_id):
                    logger.info(
                        f"Dispatching to {handler.__class__.__name__}")
                    response_text = handler.handle(utf8_text, session_id)
                    logger.info(f"Response: '{response_text[:100]}...'")
                    # Convert response back to PETSCII
                    return BaseHandler.utf8_to_petscii(response_text)

            # If no handler claims it, but a module is active, send it to that module's handler
            state = get_session_state(session_id)
            active_module = state.get('active_module')
            if active_module:
                for handler in self.handlers:
                    # A bit of a hack to see which handler corresponds to the module
                    if (active_module == 'c' and isinstance(handler, CSDBHandler)) or \
                       (active_module == 'i' and isinstance(handler, ChatHandler)):
                        logger.info(
                            f"Dispatching to active module handler {handler.__class__.__name__}")
                        response_text = handler.handle(utf8_text, session_id)
                        logger.info(f"Response: '{response_text[:100]}...'")
                        return BaseHandler.utf8_to_petscii(response_text)

            # Default response if no handler is found
            logger.warning("No handler found for the request.")
            return BaseHandler.utf8_to_petscii("Unknown command. Type 'help' for assistance.")

        except Exception as e:
            logger.error(f"Error during dispatch: {e}", exc_info=True)
            return BaseHandler.utf8_to_petscii(f"Server error: {str(e)}")


class CommandHandler:
    """Handles processing of commands from C64 client"""

    # Class-level dispatcher instance
    _dispatcher = None

    @classmethod
    def get_dispatcher(cls) -> RequestDispatcher:
        """Get or create the request dispatcher instance"""
        if cls._dispatcher is None:
            cls._dispatcher = RequestDispatcher()
        return cls._dispatcher

    @staticmethod
    def parse_packet(packet: bytes) -> Tuple[bytes, int, bytes]:
        """
        Parse a command packet from C64

        Args:
            packet: Raw packet bytes

        Returns:
            Tuple of (magic_bytes, command_id, data)

        Raises:
            ValueError: If packet is invalid
        """
        if len(packet) < 3:
            raise ValueError("Packet too short")

        magic = packet[0:2]
        if magic != MAGIC_BYTES:
            raise ValueError(f"Invalid magic bytes: {magic.hex()}")

        cmd_id = packet[2]
        data = packet[3:]

        return magic, cmd_id, data

    @staticmethod
    def handle_keypress(data: bytes) -> bytes:
        """
        Handle keypress command ($01)

        Args:
            data: Command data (1 byte PETSCII code + 1 byte modifier flags)

        Returns:
            Response packet
        """
        if len(data) < 2:
            logger.warning("Keypress data too short")
            return CommandHandler.create_response(
                ResponseType.PETSCII_NULL_TERMINATED,
                bytes([0x00])  # Empty response
            )

        petscii_code = data[0]
        modifiers = data[1]

        # Convert PETSCII to ASCII for logging
        ascii_code = Petscii.petscii2ascii(petscii_code)
        char = chr(
            ascii_code) if 32 <= ascii_code < 127 else f"<{ascii_code:02X}>"

        # Log the keypress
        mod_str = []
        if modifiers & ModifierFlags.SHIFT:
            mod_str.append("SHIFT")
        if modifiers & ModifierFlags.CTRL:
            mod_str.append("CTRL")
        if modifiers & ModifierFlags.COMMODORE:
            mod_str.append("C=")

        mod_desc = "+".join(mod_str) if mod_str else "none"
        logger.info(
            f"Keypress: {char} (PETSCII ${petscii_code:02X}), Modifiers: {mod_desc}")

        # Create echo response
        response_text = f"key: {char}\r".encode('ascii')
        petscii_response = bytes([Petscii.ascii2petscii(b)
                                 for b in response_text])
        petscii_response += bytes([0x00])  # Null terminator

        return CommandHandler.create_response(
            ResponseType.PETSCII_NULL_TERMINATED,
            petscii_response
        )

    @staticmethod
    def handle_text_input(data: bytes, session_id: int = 0) -> bytes:
        """
        Handle text input by dispatching to appropriate handler
        """
        dispatcher = CommandHandler.get_dispatcher()
        return dispatcher.dispatch(data, session_id)

    @staticmethod
    def create_response(response_type: int, data: bytes) -> bytes:
        """
        Create a response packet

        Args:
            response_type: Type of response (ResponseType constant)
            data: Response data

        Returns:
            Complete response packet with magic bytes and type
        """
        # Null-terminate only if PETSCII_NULL_TERMINATED
        if response_type == ResponseType.PETSCII_NULL_TERMINATED:
            if not data or data[-1] != 0x00:
                data += bytes([0x00])
        return MAGIC_BYTES + bytes([response_type]) + data

    @staticmethod
    def process_command(packet: bytes, session_id: int = 0) -> Optional[bytes]:
        """
        Process a complete command packet from the client
        """
        try:
            magic, cmd_id, data = CommandHandler.parse_packet(packet)
            if magic != MAGIC_BYTES:
                logger.warning("Invalid magic bytes received")
                return None

            response_data = b''
            response_type = ResponseType.PETSCII_NULL_TERMINATED

            if cmd_id == CommandID.KEYPRESS:
                response_data = CommandHandler.handle_keypress(data)
            elif cmd_id == CommandID.TEXT_INPUT:
                response_data = CommandHandler.handle_text_input(
                    data, session_id)

            if response_data:
                return CommandHandler.create_response(response_type, response_data)

        except ValueError as e:
            logger.error(f"Packet parsing error: {e}")
        except Exception as e:
            logger.error(f"Error processing command: {e}", exc_info=True)

        return None


class C64Server:
    """TCP server for C64 communication"""

    def __init__(self, host: str = '0.0.0.0', port: int = 6464):
        """
        Initialize the C64 server

        Args:
            host: Host address to bind to
            port: Port number to listen on (default 6464)
        """
        self.host = host
        self.port = port
        self.running = False
        self.server_socket = None
        self.clients = []
        self.lock = threading.Lock()

    def start(self):
        """Start the server and begin accepting connections"""
        self.server_socket = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
        self.server_socket.setsockopt(
            socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
        self.server_socket.bind((self.host, self.port))

        # Get actual port if 0 was specified (for testing)
        if self.port == 0:
            self.port = self.server_socket.getsockname()[1]

        self.server_socket.listen(5)
        self.running = True

        logger.info(f"C64 Server started on {self.host}:{self.port}")

        try:
            while self.running:
                try:
                    client_socket, address = self.server_socket.accept()
                    with self.lock:
                        self.clients.append(client_socket)
                    logger.info(f"Accepted connection from {address}")
                    # Use a unique session ID for each client connection
                    session_id = id(client_socket)
                    thread = threading.Thread(
                        target=self.handle_client, args=(client_socket, address, session_id))
                    thread.daemon = True
                    thread.start()
                except OSError:
                    # This can happen when the socket is closed by another thread
                    break
        finally:
            self.stop()

    def handle_client(self, client_socket: socket.socket, address: Tuple[str, int], session_id: int):
        """
        Handle communication with a connected client

        Args:
            client_socket: Client socket
            address: Client address tuple
            session_id: A unique ID for this client session
        """
        try:
            while self.running:
                data = client_socket.recv(1024)
                if not data:
                    break  # Connection closed
                response = CommandHandler.process_command(data, session_id)
                if response:
                    client_socket.sendall(response)
        except ConnectionResetError:
            logger.info(f"Connection reset by {address}")
        except Exception as e:
            logger.error(
                f"Error handling client {address}: {e}", exc_info=True)
        finally:
            logger.info(f"Connection from {address} closed")
            with self.lock:
                if client_socket in self.clients:
                    self.clients.remove(client_socket)
            client_socket.close()

    def stop(self):
        """Stop the server and close all connections"""
        logger.info("Stopping server...")
        self.running = False
        if self.server_socket:
            # This will unblock the accept() call
            self.server_socket.close()
            self.server_socket = None

        with self.lock:
            for client in self.clients:
                try:
                    client.shutdown(socket.SHUT_RDWR)
                    client.close()
                except OSError:
                    pass  # Ignore errors on already closed sockets
            self.clients.clear()

        logger.info("C64 Server stopped.")

    def cleanup(self):
        """Cleanup resources"""
        logger.info("Server stopped")


def main():
    """Main entry point"""
    # Ensure cloud directory is in path
    sys.path.append(os.path.dirname(os.path.abspath(__file__)))

    parser = argparse.ArgumentParser(description='C64 HDN Cloud Server')
    parser.add_argument('--host', default='0.0.0.0',
                        help='Host to bind to (default: 0.0.0.0)')
    parser.add_argument('--port', type=int, default=6464,
                        help='Port to listen on (default: 6464)')
    parser.add_argument('--debug', action='store_true',
                        help='Enable debug logging')

    args = parser.parse_args()

    if args.debug:
        logging.getLogger().setLevel(logging.DEBUG)

    server = C64Server(host=args.host, port=args.port)

    try:
        server.start()
    except KeyboardInterrupt:
        logger.info("Shutting down server...")
    finally:
        server.stop()
        server.cleanup()


if __name__ == '__main__':
    main()
