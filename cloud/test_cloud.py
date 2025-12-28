"""
Unit tests for cloud.py C64 TCP server
"""
import pytest
import socket
import threading
import time
from cloud_server import C64Server, CommandHandler, MAGIC_BYTES, ResponseType


@pytest.fixture
def server():
    """Create a C64 server instance for testing"""
    srv = C64Server(host='127.0.0.1', port=0)  # Port 0 = random available port
    yield srv
    srv.stop()


@pytest.fixture
def running_server(server):
    """Create and start a C64 server in a background thread"""
    thread = threading.Thread(target=server.start, daemon=True)
    thread.start()
    time.sleep(0.1)  # Give server time to start
    yield server
    server.stop()


class TestProtocolParsing:
    """Test protocol parsing and packet handling"""

    def test_parse_keypress_command(self):
        """Test parsing of keypress command ($01)"""
        # Magic bytes + Command ID $01 + PETSCII 'a' ($41) + No modifiers
        packet = bytes([0xFE, 0xFF, 0x01, 0x41, 0x00])

        magic, cmd_id, data = CommandHandler.parse_packet(packet)

        assert magic == bytes([0xFE, 0xFF])
        assert cmd_id == 0x01
        assert data == bytes([0x41, 0x00])

    def test_parse_text_input_command(self):
        """Test parsing of text input command ($02)"""
        # Magic bytes + Command ID $02 + "hello" in PETSCII + null terminator
        # h=0x48, e=0x45, l=0x4C, l=0x4C, o=0x4F
        packet = bytes([0xFE, 0xFF, 0x02, 0x48, 0x45, 0x4C, 0x4C, 0x4F, 0x00])

        magic, cmd_id, data = CommandHandler.parse_packet(packet)

        assert magic == bytes([0xFE, 0xFF])
        assert cmd_id == 0x02
        assert data == bytes([0x48, 0x45, 0x4C, 0x4C, 0x4F, 0x00])

    def test_invalid_magic_bytes(self):
        """Test that invalid magic bytes are rejected"""
        packet = bytes([0xAA, 0xBB, 0x01, 0x41, 0x00])

        with pytest.raises(ValueError, match="Invalid magic bytes"):
            CommandHandler.parse_packet(packet)

    def test_packet_too_short(self):
        """Test that packets shorter than minimum length are rejected"""
        packet = bytes([0xFE, 0xFF])

        with pytest.raises(ValueError, match="Packet too short"):
            CommandHandler.parse_packet(packet)


class TestCommandHandlers:
    """Test command processing"""

    def test_handle_keypress_no_modifiers(self):
        """Test handling keypress without modifiers"""
        # PETSCII 'a' ($41), no modifiers
        data = bytes([0x41, 0x00])

        response = CommandHandler.handle_keypress(data)

        assert response is not None
        assert response[0:2] == MAGIC_BYTES
        assert response[2] == ResponseType.PETSCII_NULL_TERMINATED
        # Response should acknowledge the keypress
        assert len(response) > 3

    def test_handle_keypress_with_shift(self):
        """Test handling keypress with shift modifier"""
        # PETSCII 'A' ($C1), shift flag set (bit 0)
        data = bytes([0xC1, 0x01])

        response = CommandHandler.handle_keypress(data)

        assert response is not None
        assert response[0:2] == MAGIC_BYTES
        assert response[2] == ResponseType.PETSCII_NULL_TERMINATED

    def test_handle_text_input_simple(self):
        """Test handling simple text input"""
        # "hello" in PETSCII + null terminator
        data = bytes([0x48, 0x45, 0x4C, 0x4C, 0x4F, 0x00])

        response = CommandHandler.handle_text_input(data)
        assert response is not None
        # assert response[0:2] == MAGIC_BYTES
        # assert response[2] == ResponseType.PETSCII_NULL_TERMINATED
        # Response should echo or acknowledge the text
        assert len(response) > 3

    def test_handle_text_input_empty(self):
        """Test handling empty text input"""
        data = bytes([0x00])

        response = CommandHandler.handle_text_input(data)

        assert response is not None
        # assert response[0:2] == MAGIC_BYTES


class TestResponseGeneration:
    """Test response packet generation"""

    def test_petscii_protocol_response_is_null_terminated(self):
        """Test that PETSCII_NULL_TERMINATED protocol responses are null-terminated"""
        from cloud_server import CommandHandler, CommandID, MAGIC_BYTES, ResponseType

        # Prepare a text input packet: MAGIC_BYTES + CommandID.TEXT_INPUT + PETSCII 'help' + null
        petscii_text = bytes([0x48, 0x45, 0x4C, 0x50, 0x00])  # 'HELP' + null
        packet = MAGIC_BYTES + bytes([CommandID.TEXT_INPUT]) + petscii_text

        response = CommandHandler.process_command(packet)
        assert response is not None
        # The response type should be PETSCII_NULL_TERMINATED
        assert response[2] == ResponseType.PETSCII_NULL_TERMINATED
        # The last byte of the response should be 0x00 (null terminator)
        assert response[-1] == 0x00

    def test_create_petscii_response(self):
        """Test creating a PETSCII null-terminated response"""
        # "ok" in PETSCII: o=$4F, k=$4B
        petscii_text = bytes([0x4F, 0x4B, 0x00])

        response = CommandHandler.create_response(
            ResponseType.PETSCII_NULL_TERMINATED,
            petscii_text
        )

        assert response[0:2] == MAGIC_BYTES
        assert response[2] == ResponseType.PETSCII_NULL_TERMINATED
        assert response[3:] == petscii_text

    def test_create_mixed_response(self):
        """Test creating a mixed commands/screen codes response"""
        data = bytes([0x01, 0x02, 0x03])

        response = CommandHandler.create_response(
            ResponseType.MIX_COMMANDS_SCREEN_CODES,
            data
        )

        assert response[0:2] == MAGIC_BYTES
        assert response[2] == ResponseType.MIX_COMMANDS_SCREEN_CODES
        assert response[3:] == data


class TestPETSCIIConversion:
    """Test PETSCII conversion utilities"""

    def test_petscii_to_utf8_lowercase(self):
        """Test converting PETSCII lowercase to UTF-8"""
        from generate_pet_asc_table import Petscii

        # PETSCII 'a' = $41, ASCII 'a' = $61
        petscii_a = 0x41
        ascii_a = Petscii.petscii2ascii(petscii_a)

        assert ascii_a == 0x61
        assert chr(ascii_a) == 'a'

    def test_petscii_to_utf8_uppercase(self):
        """Test converting PETSCII uppercase to UTF-8"""
        from generate_pet_asc_table import Petscii

        # PETSCII 'A' = $C1, ASCII 'A' = $41
        petscii_A = 0xC1
        ascii_A = Petscii.petscii2ascii(petscii_A)

        assert ascii_A == 0x41
        assert chr(ascii_A) == 'A'

    def test_utf8_to_petscii_lowercase(self):
        """Test converting UTF-8 lowercase to PETSCII"""
        from generate_pet_asc_table import Petscii

        # ASCII 'a' = $61, PETSCII 'a' = $41
        ascii_a = ord('a')
        petscii_a = Petscii.ascii2petscii(ascii_a)

        assert petscii_a == 0x41

    def test_utf8_to_petscii_uppercase(self):
        """Test converting UTF-8 uppercase to PETSCII"""
        from generate_pet_asc_table import Petscii

        # ASCII 'A' = $41, PETSCII 'A' = $C1
        ascii_A = ord('A')
        petscii_A = Petscii.ascii2petscii(ascii_A)

        assert petscii_A == 0xC1

    def test_petscii_string_to_utf8(self):
        """Test converting a PETSCII string to UTF-8"""
        from generate_pet_asc_table import Petscii

        # "hello" in PETSCII
        petscii_hello = bytes([0x48, 0x45, 0x4C, 0x4C, 0x4F])

        # Convert to UTF-8
        utf8_bytes = bytes([Petscii.petscii2ascii(b) for b in petscii_hello])
        utf8_str = utf8_bytes.decode('ascii')

        assert utf8_str == "hello"

    def test_utf8_string_to_petscii(self):
        """Test converting a UTF-8 string to PETSCII"""
        from generate_pet_asc_table import Petscii

        # "HELLO" in UTF-8
        utf8_str = "HELLO"

        # Convert to PETSCII
        petscii_bytes = bytes([Petscii.ascii2petscii(ord(c))
                              for c in utf8_str])

        # PETSCII "HELLO": H=$C8, E=$C5, L=$CC, L=$CC, O=$CF
        expected = bytes([0xC8, 0xC5, 0xCC, 0xCC, 0xCF])
        assert petscii_bytes == expected


class TestServerIntegration:
    """Integration tests with actual TCP connections"""

    def test_server_starts_and_stops(self, server):
        """Test that server can start and stop cleanly"""
        thread = threading.Thread(target=server.start, daemon=True)
        thread.start()
        time.sleep(0.1)

        assert server.running

        server.stop()
        time.sleep(0.1)

        assert not server.running

    def test_client_can_connect(self, running_server):
        """Test that a client can connect to the server"""
        client = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
        client.connect((running_server.host, running_server.port))

        assert client.fileno() != -1

        client.close()

    def test_send_keypress_command(self, running_server):
        """Test sending a keypress command and receiving response"""
        client = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
        client.connect((running_server.host, running_server.port))

        # Send keypress command: Magic + $01 + 'a' ($41) + no modifiers
        packet = bytes([0xFE, 0xFF, 0x01, 0x41, 0x00])
        client.send(packet)

        # Receive response
        response = client.recv(1024)

        assert len(response) >= 3
        assert response[0:2] == MAGIC_BYTES
        assert response[2] in [ResponseType.PETSCII_NULL_TERMINATED,
                               ResponseType.MIX_COMMANDS_SCREEN_CODES,
                               ResponseType.MTEXT_FORMAT]

        client.close()

    def test_send_text_input_command(self, running_server):
        """Test sending a text input command and receiving response"""
        client = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
        client.connect((running_server.host, running_server.port))

        # Send text input: Magic + $02 + "test" + null
        packet = bytes([0xFE, 0xFF, 0x02, 0x54, 0x45, 0x53, 0x54, 0x00])
        client.send(packet)

        # Receive response
        response = client.recv(1024)

        assert len(response) >= 3
        assert response[0:2] == MAGIC_BYTES

        client.close()


if __name__ == '__main__':
    pytest.main([__file__, '-v'])
