Create a python script parse_simple.py that will gather input from console, parse input and output following structure
{"command": <command code>, "name":  <command name>, "args": [...]}
Loop to ask for input again.
Use the attached BNF gramar for parsing.
Do not use try catch. Always only handle only single characer at a time. Create a parsing tree, character by character. Make it efficient.
If an argument does not match the gramar then return {"error": "Syntax error."}
If input has more arguments than what then gramar allows then return {"error": "Too many args."}
If command does not exist then return {"error": "Command not found."}
Instead of using startswith() and other complex functions, utilize these functions:
```
def next_char():
    global input_cursor
    input_cursor += 1
    if input_cursor < len(input_str):
        return input_str[input_cursor]
    return None


def peek_char():
    if input_cursor + 1 < len(input_str):
        return input_str[input_cursor + 1]
    return None


def skip_whitespace():
    global input_cursor
    while (
        input_cursor + 1 < len(input_str)
        and input_str[input_cursor + 1] == " "
    ):
        input_cursor += 1


def parse_hex_digit():
    c = next_char()
    if c is not None and c.upper() in "0123456789ABCDEF":
        return c
    return None


def parse_address():
    addr = ""
    for _ in range(4):
        d = parse_hex_digit()
        if d is None:
            return None
        addr += d
    return addr


def parse_quoted_string():
    # expects opening quote already consumed
    s = ""
    while True:
        c = next_char()
        if c is None:
            return None
        if c == '"':
            break
        s += c
    return s


def parse_file_or_path():
    # Try quoted filename/path
    c = peek_char()
    if c == '"':
        next_char()  # consume quote
        s = parse_quoted_string()
        if s is None:
            return None
        return s
    # Unquoted: parse up to space or end
    s = ""
    while True:
        c = peek_char()
        if c is None or c == " ":
            break
        next_char()
        s += input_str[input_cursor]
    if not s:
        return None
    return s
```

The command parsing logic now assigns a command code as soon as the command is resolved, using the defined constants, and dispatches based on that code. This matches your request for more efficient command resolution. Use code like this:

```
def parse_command():
    global input_cursor
    skip_whitespace()
    cmd_start = input_cursor + 1
    cmd_end = cmd_start
    cmd_code = None
    # Try to resolve command and assign code as soon as possible
    if cmd_end < len(input_str) and input_str[cmd_end] == "l":
        cmd_end += 1
        if cmd_end == len(input_str) or input_str[cmd_end] == " ":
            cmd_code = CMD_L
        elif input_str[cmd_end] == "s":
            cmd_end += 1
            if cmd_end == len(input_str) or input_str[cmd_end] == " ":
                cmd_code = CMD_LS
        elif input_str[cmd_end] == "l":
            cmd_end += 1
            if cmd_end == len(input_str) or input_str[cmd_end] == " ":
                cmd_code = CMD_LL
    elif (
        cmd_end + 3 < len(input_str)
        and input_str[cmd_end: cmd_end + 4] == "help"
        and (cmd_end + 4 == len(input_str) or input_str[cmd_end + 4] == " ")
    ):
        cmd_code = CMD_HELP
        cmd_end += 4
    if cmd_code is None:
        return {"error": "Command not found."}
    input_cursor = cmd_end - 1
    skip_whitespace()
    args = []
    if cmd_code == CMD_L:
        # l <file_or_path> [address]
        arg1 = parse_file_or_path()
        if arg1 is None:
            return {"error": "Syntax error."}
        skip_whitespace()
        # Optional address
        c = peek_char()
        if c is not None and c != " ":
            arg2 = parse_address()
            if arg2 is None:
                return {"error": "Syntax error."}
            args = [arg1, arg2]
            skip_whitespace()
        else:
            args = [arg1]
        # Check for extra args
        skip_whitespace()
        if peek_char() is not None:
            return {"error": "Too many args."}
        return {"command": CMD_L, "name": "l", "args": args}
    elif cmd_code == CMD_LS:
        # ls [file_or_path]
        c = peek_char()
        if c is not None and c != " ":
            arg1 = parse_file_or_path()
            if arg1 is None:
                return {"error": "Syntax error."}
            args = [arg1]
            skip_whitespace()
        # Check for extra args
        skip_whitespace()
        if peek_char() is not None:
            return {"error": "Too many args."}
        return {"command": CMD_LS, "name": "ls", "args": args}
    elif cmd_code == CMD_LL:
        # ll [file_or_path]
        c = peek_char()
        if c is not None and c != " ":
            arg1 = parse_file_or_path()
            if arg1 is None:
                return {"error": "Syntax error."}
            args = [arg1]
            skip_whitespace()
        # Check for extra args
        skip_whitespace()
        if peek_char() is not None:
            return {"error": "Too many args."}
        return {"command": CMD_LL, "name": "ll", "args": args}
    elif cmd_code == CMD_HELP:
        # help (no args)
        skip_whitespace()
        if peek_char() is not None:
            return {"error": "Too many args."}
        return {"command": CMD_HELP, "name": "help", "args": []}
    return {"error": "Command not found."}
```

Run ```autopep8 --in-place parser/parse_simple.py```. Fix any errors.
Run ```flake8 parser/parse_simple.py```. Fix any errors.
Run ```pytest parser/test_parse_simple.py``` and fix the code based on any failing tests.
Run the above tests once again after fixing the code to ensure all tests pass.
