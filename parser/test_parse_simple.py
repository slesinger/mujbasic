import parse_simple
import unittest
import builtins
from io import StringIO
import sys

import os
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))


class TestParseSimple(unittest.TestCase):
    def setUp(self):
        self.orig_input = builtins.input
        self.orig_stdout = sys.stdout
        self.output = StringIO()
        sys.stdout = self.output

    def tearDown(self):
        builtins.input = self.orig_input
        sys.stdout = self.orig_stdout

    def run_parser(self, line):
        parse_simple.input_str = line
        parse_simple.input_cursor = -1
        return parse_simple.parse_command()

    def test_file_space_command(self):
        result = self.run_parser('l "FILE S MEZEROU.PRG" 1234')
        self.assertEqual(
            result, {"command": 81, "name": "l", "args": ["FILE S MEZEROU.PRG", "1234"]})

    def test_file_no_quotes_command(self):
        result = self.run_parser('l FILE.PRG 1234')
        self.assertEqual(
            result, {"command": 81, "name": "l", "args": ["FILE.PRG", "1234"]})

    def test_load_command_no_addr(self):
        result = self.run_parser('l FILE.PRG')
        self.assertEqual(result, {"command": 81, "name": "l", "args": ["FILE.PRG"]})

    def test_load_command_syntax_error(self):
        result = self.run_parser('l "FILE.PRG" 12G4')
        self.assertEqual(result, {"error": "Syntax error."})

    def test_load_command_too_many_args(self):
        result = self.run_parser('l "FILE.PRG" 1234 5678')
        self.assertEqual(result, {"error": "Too many args."})

    def test_ll_solo_command(self):
        result = self.run_parser('ll')
        self.assertEqual(result, {"command": 25, "name": "ll", "args": []})

    def test_ls_command(self):
        result = self.run_parser('ls')
        self.assertEqual(result, {"command": 12, "name": "ls", "args": []})

    def test_ls_with_drive_command(self):
        result = self.run_parser('ls 8:SOMDIR')
        self.assertEqual(result, {"command": 12, "name": "ls", "args": ["8:SOMDIR"]})

    def test_ll_with_drive_absolute_command(self):
        result = self.run_parser('ll 8:/ABCDIR')
        self.assertEqual(result, {"command": 25, "name": "ll", "args": ["8:/ABCDIR"]})

    def test_help_command(self):
        result = self.run_parser('help')
        self.assertEqual(result, {"command": 129, "name": "help", "args": []})

    def test_command_not_found(self):
        result = self.run_parser('foo')
        self.assertEqual(result, {"error": "Command not found."})

    def test_too_many_args_ls(self):
        result = self.run_parser('ls DIR extra')
        self.assertEqual(result, {"error": "Too many args."})

    def test_quoted_ll_full(self):
        result = self.run_parser('ll "8:/AB/CD IR/hon za.PRG"')
        self.assertEqual(result, {"command": 25, "name": "ll", "args": ["8:/AB/CD IR/hon za.PRG"]})

    def test_quoted_ll_file(self):
        result = self.run_parser('ll "8:/ABC DIR.Prg"')
        self.assertEqual(result, {"command": 25, "name": "ll", "args": ["8:/ABC DIR.Prg"]})

    def test_too_many_args_help(self):
        result = self.run_parser('help extra')
        self.assertEqual(result, {"error": "Too many args."})


if __name__ == '__main__':
    unittest.main()
