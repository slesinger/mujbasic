import sys
import re


class Parser:
    def __init__(self, text):
        self.text = text.strip()
        self.pos = 0
        self.error = None

    def peek(self):
        return self.text[self.pos] if self.pos < len(self.text) else None

    def next(self):
        c = self.peek()
        if c is not None:
            self.pos += 1
        return c

    def expect(self, expected):
        c = self.next()
        if c != expected:
            self.error = f"Expected '{expected}', got '{c}' at position {self.pos}"
        return c

    def parse_drive_number(self):
        for d in ["8", "9", "10", "11", "14"]:
            if self.pos + len(d) <= len(self.text) and self.text[self.pos:self.pos+len(d)] == d:
                self.pos += len(d)
                return d
        self.error = f"Expected drive number at position {self.pos}"
        return None

    def parse_directory_path(self):
        # <directory_path> ::= [ <drive_number> ":" ] <file_char> { <file_char> | "/" }
        start_pos = self.pos
        drive = None
        for d in ["8", "9", "10", "11", "14"]:
            if self.pos + len(d) <= len(self.text) and self.text[self.pos:self.pos+len(d)] == d:
                self.pos += len(d)
                drive = d
                break
        if drive:
            if self.peek() == ":":
                self.next()
            else:
                self.pos = start_pos  # rewind if not a drive path
                drive = None
        chars = []
        while True:
            c = self.peek()
            if c and (c.isalnum() or c == "." or c == "/"):
                chars.append(self.next())
            else:
                break
        if not chars and not drive:
            self.error = "Expected directory path"
            return None
        path = ''.join(chars)
        if drive:
            return f"{drive}:{path}"
        else:
            return path

    def parse(self):
        c = self.peek()
        if c is None:
            self.error = "Empty input"
            return None
        # Try each command type in order, multi-char first
        if self.text.startswith("md", self.pos):
            return self.parse_md_command()
        elif self.text.startswith("ls", self.pos):
            return self.parse_ls_ll_command()
        elif self.text.startswith("ll", self.pos):
            return self.parse_ls_ll_command()
        elif self.text.startswith("cd", self.pos):
            return self.parse_cd_command()
        elif self.text.startswith("rd", self.pos):
            return self.parse_rd_rm_command()
        elif self.text.startswith("rm", self.pos):
            return self.parse_rd_rm_command()
        elif c == "A":
            return self.parse_assemble_command()
        elif c == "B":
            return self.parse_basic_data_command()
        elif c == "C":
            return self.parse_convert_program_command()
        elif c == "D":
            return self.parse_disassemble_command()
        elif c == "F":
            return self.parse_find_command()
        elif c == "G":
            return self.parse_go_command()
        elif c == "I":
            return self.parse_io_device_command()
        elif c == "K":
            return self.parse_inspect_command()
        elif c == "L":
            return self.parse_load_command()
        elif c == "M":
            return self.parse_memory_dump_command()
        elif c == "O":
            return self.parse_occupy_command()
        elif c == "P":
            return self.parse_printer_command()
        elif c == "R":
            return self.parse_register_command()
        elif c == "S":
            return self.parse_save_command()
        elif c == "V":
            return self.parse_move_addresses_command()
        elif c == "W":
            return self.parse_write_command()
        elif c == "=":
            return self.parse_check_equality_command()
        elif c == "X":
            return self.parse_exit_smon_command()
        elif c == "#":
            return self.parse_convert_decimal_command()
        elif c == "$":
            return self.parse_convert_hex_command()
        elif c == "%":
            return self.parse_convert_binary_command()
        elif c == "?":
            return self.parse_hex_add_sub_command()
        elif c == "@":
            return self.parse_at_command()
        else:
            self.error = f"Unknown command start: '{c}'"
            return None

    # Helper methods for grammar elements
    def parse_hex_digit(self):
        c = self.peek()
        if c and c in "0123456789ABCDEFabcdef":
            return self.next()
        self.error = f"Expected hex digit at position {self.pos}"
        return None

    def parse_address(self):
        addr = []
        for _ in range(4):
            d = self.parse_hex_digit()
            if self.error:
                return None
            addr.append(d)
        return ''.join(addr)

    def parse_byte_value(self):
        bv = []
        for _ in range(2):
            d = self.parse_hex_digit()
            if self.error:
                return None
            bv.append(d)
        return ''.join(bv)

    def parse_file_char(self):
        c = self.peek()
        if c and (c.isalnum() or c == "."):
            return self.next()
        self.error = f"Expected file char at position {self.pos}"
        return None

    def parse_file_path(self):
        chars = []
        while True:
            c = self.peek()
            if c and (c.isalnum() or c == "."):
                chars.append(self.next())
            else:
                break
        if not chars:
            self.error = "Expected file path"
            return None
        return ''.join(chars)

    def parse_filename(self):
        if self.peek() != '"':
            self.error = 'Expected opening " for filename'
            return None
        self.next()
        path = self.parse_file_path()
        if self.error:
            return None
        if self.peek() != '"':
            self.error = 'Expected closing " for filename'
            return None
        self.next()
        return path

    def parse_decimal_number(self):
        digits = []
        while self.peek() and self.peek().isdigit():
            digits.append(self.next())
        if not digits:
            self.error = "Expected decimal number"
            return None
        return ''.join(digits)

    def parse_binary_number(self):
        bits = []
        while self.peek() in ("0", "1"):
            bits.append(self.next())
        if not bits:
            self.error = "Expected binary number"
            return None
        return ''.join(bits)

    # Command parsers (implement a few as examples, add more as needed)
    def parse_assemble_command(self):
        self.expect("A")
        if self.error:
            return None
        addr = self.parse_address()
        if self.error:
            return None
        # Skipping <assemble_data> and "F" for brevity
        return {"command": "A", "args": [addr]}

    def parse_basic_data_command(self):
        self.expect("B")
        if self.error:
            return None
        addr = self.parse_address()
        if self.error:
            return None
        end_addr = self.parse_address()
        if self.error:
            return None
        return {"command": "B", "args": [addr, end_addr]}

    def parse_convert_program_command(self):
        self.expect("C")
        if self.error:
            return None
        args = []
        for _ in range(5):
            a = self.parse_address()
            if self.error:
                return None
            args.append(a)
        return {"command": "C", "args": args}

    def parse_disassemble_command(self):
        self.expect("D")
        if self.error:
            return None
        addr = self.parse_address()
        if self.error:
            return None
        end_addr = None
        if self.peek() and re.match(r"[0-9A-Fa-f]", self.peek()):
            end_addr = self.parse_address()
            if self.error:
                return None
        args = [addr]
        if end_addr:
            args.append(end_addr)
        return {"command": "D", "args": args}

    def parse_find_command(self):
        self.expect("F")
        if self.error:
            return None
        bv = self.parse_byte_value()
        if self.error:
            return None
        while self.peek() and (self.peek() in "0123456789ABCDEFabcdef*" or self.peek() == "*"):
            if self.peek() == "*":
                self.next()
            else:
                self.parse_byte_value()
                if self.error:
                    return None
        if self.peek() != ",":
            self.error = "Expected ',' after byte values"
            return None
        self.next()
        addr1 = self.parse_address()
        if self.error:
            return None
        addr2 = self.parse_address()
        if self.error:
            return None
        return {"command": "F", "args": [bv, addr1, addr2]}

    def parse_go_command(self):
        self.expect("G")
        if self.error:
            return None
        addr = None
        if self.peek() and re.match(r"[0-9A-Fa-f]", self.peek()):
            addr = self.parse_address()
            if self.error:
                return None
        return {"command": "G", "args": [addr] if addr else []}

    def parse_io_device_command(self):
        self.expect("I")
        if self.error:
            return None
        bv = self.parse_byte_value()
        if self.error:
            return None
        return {"command": "I", "args": [bv]}

    def parse_inspect_command(self):
        self.expect("K")
        if self.error:
            return None
        addr = self.parse_address()
        if self.error:
            return None
        end_addr = None
        if self.peek() and re.match(r"[0-9A-Fa-f]", self.peek()):
            end_addr = self.parse_address()
            if self.error:
                return None
        args = [addr]
        if end_addr:
            args.append(end_addr)
        return {"command": "K", "args": args}

    def parse_load_command(self):
        self.expect("L")
        if self.error:
            return None
        filename = self.parse_filename()
        if self.error:
            return None
        addr = None
        if self.peek() and re.match(r"[0-9A-Fa-f]", self.peek()):
            addr = self.parse_address()
            if self.error:
                return None
        args = [filename]
        if addr:
            args.append(addr)
        return {"command": "L", "args": args}

    def parse_memory_dump_command(self):
        self.expect("M")
        if self.error:
            return None
        addr = self.parse_address()
        if self.error:
            return None
        end_addr = None
        if self.peek() and re.match(r"[0-9A-Fa-f]", self.peek()):
            end_addr = self.parse_address()
            if self.error:
                return None
        args = [addr]
        if end_addr:
            args.append(end_addr)
        return {"command": "M", "args": args}

    def parse_occupy_command(self):
        self.expect("O")
        if self.error:
            return None
        addr1 = self.parse_address()
        if self.error:
            return None
        addr2 = self.parse_address()
        if self.error:
            return None
        bv = self.parse_byte_value()
        if self.error:
            return None
        return {"command": "O", "args": [addr1, addr2, bv]}

    def parse_printer_command(self):
        self.expect("P")
        if self.error:
            return None
        bv = self.parse_byte_value()
        if self.error:
            return None
        return {"command": "P", "args": [bv]}

    def parse_register_command(self):
        self.expect("R")
        if self.error:
            return None
        return {"command": "R", "args": []}

    def parse_save_command(self):
        self.expect("S")
        if self.error:
            return None
        args = []
        if self.peek() == '"':
            filename = self.parse_filename()
            if self.error:
                return None
            addr1 = self.parse_address()
            if self.error:
                return None
            addr2 = self.parse_address()
            if self.error:
                return None
            args = [filename, addr1, addr2]
        return {"command": "S", "args": args}

    def parse_move_addresses_command(self):
        self.expect("V")
        if self.error:
            return None
        args = []
        for _ in range(5):
            a = self.parse_address()
            if self.error:
                return None
            args.append(a)
        return {"command": "V", "args": args}

    def parse_write_command(self):
        self.expect("W")
        if self.error:
            return None
        addr1 = self.parse_address()
        if self.error:
            return None
        addr2 = self.parse_address()
        if self.error:
            return None
        addr3 = self.parse_address()
        if self.error:
            return None
        return {"command": "W", "args": [addr1, addr2, addr3]}

    def parse_check_equality_command(self):
        self.expect("=")
        if self.error:
            return None
        addr1 = self.parse_address()
        if self.error:
            return None
        addr2 = self.parse_address()
        if self.error:
            return None
        return {"command": "=", "args": [addr1, addr2]}

    def parse_exit_smon_command(self):
        self.expect("X")
        if self.error:
            return None
        return {"command": "X", "args": []}

    def parse_convert_decimal_command(self):
        self.expect("#")
        if self.error:
            return None
        num = self.parse_decimal_number()
        if self.error:
            return None
        return {"command": "#", "args": [num]}

    def parse_convert_hex_command(self):
        self.expect("$")
        if self.error:
            return None
        addr = self.parse_address()
        if self.error:
            return None
        return {"command": "$", "args": [addr]}

    def parse_convert_binary_command(self):
        self.expect("%")
        if self.error:
            return None
        num = self.parse_binary_number()
        if self.error:
            return None
        return {"command": "%", "args": [num]}

    def parse_hex_add_sub_command(self):
        self.expect("?")
        if self.error:
            return None
        addr1 = self.parse_address()
        if self.error:
            return None
        op = self.next()
        if op not in "+-":
            self.error = "Expected '+' or '-'"
            return None
        addr2 = self.parse_address()
        if self.error:
            return None
        return {"command": "?", "args": [addr1, op, addr2]}

    def parse_at_command(self):
        self.expect("@")
        if self.error:
            return None
        drive = None
        if self.peek() and self.peek().isdigit():
            drive = self.parse_drive_number()
            if self.error:
                return None
        return {"command": "@", "args": [drive] if drive else []}

    def parse_ls_ll_command(self):
        if self.text.startswith("ls", self.pos):
            self.pos += 2
            path = None
            if self.peek() and (self.peek().isalnum() or self.peek() == "/"):
                path = self.parse_file_path()
                if self.error:
                    return None
            return {"command": "ls", "args": [path] if path else []}
        elif self.text.startswith("ll", self.pos):
            self.pos += 2
            path = self.parse_file_path()
            if self.error:
                return None
            return {"command": "ll", "args": [path]}
        else:
            self.error = "Expected 'ls' or 'll'"
            return None

    def parse_cd_command(self):
        if self.text.startswith("cd", self.pos):
            self.pos += 2
            path = self.parse_file_path()
            if self.error:
                return None
            return {"command": "cd", "args": [path]}
        else:
            self.error = "Expected 'cd'"
            return None

    def parse_md_command(self):
        if self.text.startswith("md", self.pos):
            self.pos += 2
            path = self.parse_file_path()
            if self.error:
                return None
            return {"command": "md", "args": [path]}
        else:
            self.error = "Expected 'md'"
            return None

    def parse_rd_rm_command(self):
        if self.text.startswith("rd", self.pos):
            self.pos += 2
            path = self.parse_file_path()
            if self.error:
                return None
            return {"command": "rd", "args": [path]}
        elif self.text.startswith("rm", self.pos):
            self.pos += 2
            path = self.parse_file_path()
            if self.error:
                return None
            return {"command": "rm", "args": [path]}
        else:
            self.error = "Expected 'rd' or 'rm'"
            return None


def main():
    line = input("Enter command: ")
    parser = Parser(line)
    result = parser.parse()
    if parser.error:
        print(f"Parse error: {parser.error}")
    else:
        print(result)


if __name__ == "__main__":
    main()
