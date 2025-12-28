#!/usr/bin/env python3
"""
Test client for C64 Cloud Server

Simulates a C64 client sending commands and receiving responses.
Useful for testing the TCP communication protocol.
"""
import socket
import sys
from generate_pet_asc_table import Petscii

# Protocol constants
MAGIC_BYTES = bytes([0xFE, 0xFF])


class CommandID:
    """Command IDs to send to server"""
    KEYPRESS = 0x01
    TEXT_INPUT = 0x02


class ResponseType:
    """Response types from server"""
    PETSCII_NULL_TERMINATED = 0x01
    MIX_COMMANDS_SCREEN_CODES = 0x02
    MTEXT_FORMAT = 0x03


class C64TestClient:
    """Test client that simulates C64 communication"""

    def __init__(self, host: str = '127.0.0.1', port: int = 6464):
        """
        Initialize test client

        Args:
            host: Server host address
            port: Server port number
        """
        self.host = host
        self.port = port
        self.socket = None

    def connect(self):
        """Connect to the server"""
        self.socket = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
        self.socket.connect((self.host, self.port))
        print(f"Connected to {self.host}:{self.port}")

    def disconnect(self):
        """Disconnect from the server"""
        if self.socket:
            self.socket.close()
            print("Disconnected")

    def send_keypress(self, key: str, shift: bool = False, ctrl: bool = False, commodore: bool = False):
        """
        Send a keypress command

        Args:
            key: Character to send
            shift: Shift key pressed
            ctrl: Control key pressed
            commodore: Commodore key pressed
        """
        # Convert to PETSCII
        ascii_code = ord(key)
        petscii_code = Petscii.ascii2petscii(ascii_code)

        # Build modifier flags
        modifiers = 0
        if shift:
            modifiers |= 0x01
        if ctrl:
            modifiers |= 0x02
        if commodore:
            modifiers |= 0x04

        # Build packet
        packet = MAGIC_BYTES + \
            bytes([CommandID.KEYPRESS, petscii_code, modifiers])

        print(f"\nSending keypress: '{key}' (PETSCII ${petscii_code:02X})")
        print(f"  Modifiers: Shift={shift}, Ctrl={ctrl}, C={commodore}")
        print(f"  Packet: {packet.hex()}")

        self.socket.send(packet)

        # Receive response
        response = self.socket.recv(4096)
        self.print_response(response)
        return self.decode_response(response)

    def send_text(self, text: str):
        """
        Send text input command

        Args:
            text: Text string to send
        """
        # Convert to PETSCII
        petscii_bytes = bytes([Petscii.ascii2petscii(ord(c)) for c in text])

        # Build packet (with null terminator)
        packet = MAGIC_BYTES + \
            bytes([CommandID.TEXT_INPUT]) + petscii_bytes + bytes([0x00])

        print(f"\nSending text: '{text}'")
        print(f"  PETSCII: {petscii_bytes.hex()}")
        print(f"  Packet: {packet.hex()}")

        self.socket.send(packet)

        # Receive response
        response = self.socket.recv(4096)
        self.print_response(response)
        return self.decode_response(response)

    def decode_response(self, response: bytes):
        """
        Decode response and return text

        Args:
            response: Response packet from server

        Returns:
            Decoded text string or None if decoding fails
        """
        if len(response) < 3:
            return None

        # Check magic bytes
        magic = response[0:2]
        if magic != MAGIC_BYTES:
            return None

        # Get response type
        resp_type = response[2]
        data = response[3:]

        # Try to decode PETSCII to UTF-8
        if resp_type == ResponseType.PETSCII_NULL_TERMINATED:
            # Find null terminator
            null_pos = data.find(0x00)
            if null_pos != -1:
                petscii_data = data[:null_pos]
            else:
                petscii_data = data

            if len(petscii_data) > 0:
                # Convert to ASCII/UTF-8
                try:
                    ascii_bytes = bytes([Petscii.petscii2ascii(b)
                                        for b in petscii_data])
                    text = ascii_bytes.decode('ascii')
                    return text
                except Exception:
                    return None

        return None

    def print_response(self, response: bytes):
        """
        Print received response

        Args:
            response: Response packet from server
        """
        print(f"\nReceived response ({len(response)} bytes): {response.hex()}")

        if len(response) < 3:
            print("  Response too short!")
            return

        # Check magic bytes
        magic = response[0:2]
        if magic != MAGIC_BYTES:
            print(f"  Invalid magic bytes: {magic.hex()}")
            return

        # Get response type
        resp_type = response[2]
        data = response[3:]

        type_names = {
            ResponseType.PETSCII_NULL_TERMINATED: "PETSCII NULL-TERMINATED",
            ResponseType.MIX_COMMANDS_SCREEN_CODES: "MIX COMMANDS/SCREEN CODES",
            ResponseType.MTEXT_FORMAT: "MTEXT FORMAT"
        }

        type_name = type_names.get(resp_type, f"UNKNOWN (${resp_type:02X})")
        print(f"  Response type: {type_name}")

        # Try to decode PETSCII to UTF-8
        if resp_type == ResponseType.PETSCII_NULL_TERMINATED:
            # Find null terminator
            null_pos = data.find(0x00)
            if null_pos != -1:
                petscii_data = data[:null_pos]
            else:
                petscii_data = data

            if len(petscii_data) > 0:
                # Convert to ASCII/UTF-8
                try:
                    ascii_bytes = bytes([Petscii.petscii2ascii(b)
                                        for b in petscii_data])
                    text = ascii_bytes.decode('ascii')
                    print(f"  Text: '{text}'")
                except Exception as e:
                    print(f"  Could not decode: {e}")
                    print(f"  Raw data: {petscii_data.hex()}")
            else:
                print("  (empty response)")
        else:
            print(f"  Data: {data.hex()}")


def interactive_mode(client: C64TestClient):
    """
    Interactive mode for testing

    Args:
        client: Connected test client
    """
    print("\n=== C64 Test Client - Interactive Mode ===")
    print("Commands:")
    print("  k <char>          - Send keypress (e.g., 'k a')")
    print("  ks <char>         - Send keypress with SHIFT")
    print("  kc <char>         - Send keypress with CTRL")
    print("  t <text>          - Send text input (e.g., 't hello')")
    print("  q                 - Quit")
    print()

    while True:
        try:
            cmd = input("> ").strip()

            if not cmd:
                continue

            if cmd == 'q':
                break

            parts = cmd.split(maxsplit=1)

            if parts[0] == 'k' and len(parts) == 2:
                if len(parts[1]) > 0:
                    client.send_keypress(parts[1][0])

            elif parts[0] == 'ks' and len(parts) == 2:
                if len(parts[1]) > 0:
                    client.send_keypress(parts[1][0], shift=True)

            elif parts[0] == 'kc' and len(parts) == 2:
                if len(parts[1]) > 0:
                    client.send_keypress(parts[1][0], ctrl=True)

            elif parts[0] == 't' and len(parts) == 2:
                client.send_text(parts[1])

            else:
                # Default: treat as text input
                client.send_text(cmd)

        except KeyboardInterrupt:
            print()
            break
        except Exception as e:
            print(f"Error: {e}")


def demo_mode(client: C64TestClient):
    """
    Demonstration mode with predefined commands

    Args:
        client: Connected test client
    """
    print("\n=== C64 Test Client - Demo Mode ===\n")

    # Send some test keypresses
    print("--- Test 1: Simple keypress ---")
    client.send_keypress('a')

    print("\n--- Test 2: Keypress with SHIFT ---")
    client.send_keypress('A', shift=True)

    print("\n--- Test 3: Send text ---")
    client.send_text("hello")

    print("\n--- Test 4: Send uppercase text ---")
    client.send_text("HELLO")

    print("\n--- Test 5: Send command ---")
    client.send_text("dir")

    print("\n--- Demo complete ---")


def main():
    """Main entry point"""
    import argparse

    parser = argparse.ArgumentParser(description='C64 Test Client')
    parser.add_argument('--host', default='127.0.0.1',
                        help='Server host (default: 127.0.0.1)')
    parser.add_argument('--port', type=int, default=6464,
                        help='Server port (default: 6464)')
    parser.add_argument('--demo', action='store_true',
                        help='Run demo mode instead of interactive')

    args = parser.parse_args()

    client = C64TestClient(host=args.host, port=args.port)

    try:
        client.connect()

        if args.demo:
            demo_mode(client)
        else:
            interactive_mode(client)

    except ConnectionRefusedError:
        print(f"Error: Could not connect to {args.host}:{args.port}")
        print("Make sure the server is running.")
        sys.exit(1)
    except Exception as e:
        print(f"Error: {e}")
        sys.exit(1)
    finally:
        client.disconnect()


if __name__ == '__main__':
    main()
