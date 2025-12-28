import unittest
from unittest.mock import patch, MagicMock
from cloud_test_client import C64TestClient, ResponseType, MAGIC_BYTES

HOST = '127.0.0.1'
PORT = 6464


class TestC64TestClient(unittest.TestCase):
    def setUp(self):
        self.client = C64TestClient(host=HOST, port=PORT)
        self.client.socket = MagicMock()

    def test_connect_and_disconnect(self):
        with patch('socket.socket') as mock_socket:
            instance = mock_socket.return_value
            self.client.connect()
            instance.connect.assert_called_with((HOST, PORT))
            self.client.disconnect()
            instance.close.assert_called()

    def test_send_keypress(self):
        # Simulate server response
        self.client.socket.recv.return_value = MAGIC_BYTES + \
            bytes([ResponseType.PETSCII_NULL_TERMINATED]) + b'abc\x00'
        with patch('cloud_test_client.Petscii.ascii2petscii', return_value=65):
            with patch('cloud_test_client.Petscii.petscii2ascii', side_effect=lambda b: b):
                self.client.send_keypress('A')
                self.client.socket.send.assert_called()
                self.client.socket.recv.assert_called()

    def test_send_text(self):
        self.client.socket.recv.return_value = MAGIC_BYTES + \
            bytes([ResponseType.PETSCII_NULL_TERMINATED]) + b'hello\x00'
        with patch('cloud_test_client.Petscii.ascii2petscii', side_effect=lambda c: c):
            with patch('cloud_test_client.Petscii.petscii2ascii', side_effect=lambda b: b):
                self.client.send_text('hello')
                self.client.socket.send.assert_called()
                self.client.socket.recv.assert_called()

    def test_scenario_csdb_find_error(self):
        # Simulate responses for scenario: send 'c:', expect 'csdb mode', send 'find hondani', expect "error: 'name'"
        # Note: PETSCII uppercase letters become lowercase when converted back to ASCII
        responses = [
            MAGIC_BYTES +
            bytes([ResponseType.PETSCII_NULL_TERMINATED]) + b'csdb mode\x00',
            MAGIC_BYTES +
            bytes([ResponseType.PETSCII_NULL_TERMINATED]) + b"error: 'name'\x00",
        ]
        self.client.socket.recv.side_effect = responses

        resp1 = self.client.send_text('c:')
        self.assertEqual(resp1, 'csdb mode')

        resp2 = self.client.send_text('find hondani')
        self.assertEqual(resp2, "error: 'name'")

    def test_cd_to_meetro(self):
        # Simulate the full session for navigating to Meetro release and file
        responses = [
            # 'c:'
            MAGIC_BYTES + bytes([ResponseType.PETSCII_NULL_TERMINATED]) + b'CSDB mode\x00',
            # 'cd group'
            MAGIC_BYTES + bytes([ResponseType.PETSCII_NULL_TERMINATED]) + b'Switched to group directory.\x00',
            # 'pwd'
            MAGIC_BYTES + bytes([ResponseType.PETSCII_NULL_TERMINATED]) + b'c:/group\x00',
            # 'cd 901'
            MAGIC_BYTES + bytes([ResponseType.PETSCII_NULL_TERMINATED]) + (
                b'Hondani (HDN) [Czech Republic]\nType: Demo Group\n\nAll Members:\n'
                b'18011  Artcore (ex) - Graphician\n18012  Dan (ex) - Coder\n2588   Honza (ex) - Coder, Swapper\n\nReleases: (8)\n'
                b'248345 Meetro 2024 (2024) [Demo]\n60398  Cursor I (1993) [Demo]\n83353  Contact File (1993) [One-File Dem\n'
                b'221227 Makulenko (1993) [One-File Demo]\n188108 Save New York (1993) [Crack]\n221225 Stix (1993) [Crack]\n'
                b'221226 Street Machine (1993) [Crack]\n221224 Yes Name Mikrodemo (1993) [Demo]\n\x00'
            ),
            # 'cd /release/248345'
            MAGIC_BYTES + bytes([ResponseType.PETSCII_NULL_TERMINATED]) + (
                b'Release: Meetro 2024\nReleased by: 901 Hondani\nRelease Date: 16 December 2024\nType: C64 Demo\n'
                b'User rating: 7.8/10 (8 votes)\n\nFiles:\n305029 Meetro2024-Hondani.zip (193 d/l)\x00'
            ),
            # 'cd 305029'
            MAGIC_BYTES + bytes([ResponseType.PETSCII_NULL_TERMINATED]) + (
                b'Released by: 7 Oxyron\nRelease Date: Groups\nType: Skijumper messes Christmas\x00'
            ),
        ]
        self.client.socket.recv.side_effect = responses

        # Step 1: c:
        resp = self.client.send_text('c:')
        self.assertEqual(resp, 'csdb mode')

        # Step 2: cd group
        resp = self.client.send_text('cd group')
        self.assertEqual(resp, 'switched to group directory.')

        # Step 3: pwd
        resp = self.client.send_text('pwd')
        self.assertEqual(resp, 'c:/group')

        # Step 4: cd 901
        resp = self.client.send_text('cd 901')
        self.assertTrue(resp.startswith('hondani (hdn) [czech republic]'))
        self.assertIn('meetro 2024', resp)

        # Step 5: cd /release/248345
        resp = self.client.send_text('cd /release/248345')
        self.assertTrue(resp.startswith('release: meetro 2024'))
        self.assertIn('305029 meetro2024-hondani.zip', resp)

        # Step 6: cd 305029
        resp = self.client.send_text('cd 305029')
        self.assertIn('released by: 7 oxyron', resp)
        self.assertIn('skijumper messes christmas', resp)


if __name__ == '__main__':
    unittest.main()
