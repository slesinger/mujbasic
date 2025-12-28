# C64 HDN Cloud Server

TCP server for C64 communication with PETSCII protocol support.

## Overview

This application receives TCP data as commands from a C64 computer and responds with data. It can run on a local PC or in a serverless cloud environment. The C64 client requires a C64 Ultimate with network target.

## Files

- `cloud.py` - Main TCP server implementation with request dispatcher
- `base_handler.py` - Base class for all request handlers
- `chat_handler.py` - LLM-based chat handler (I: prefix)
- `help_handler.py` - Help system handler (help prefix)
- `python_eval_handler.py` - Python expression evaluator (? prefix)
- `csdb_handler.py` - CSDB.dk API integration (c: prefix)
- `test_cloud.py` - Pytest unit tests for core functionality
- `test_handlers.py` - Pytest unit tests for request handlers
- `test_client.py` - Test client simulator for development/debugging
- `generate_pet_asc_table.py` - PETSCII ↔ ASCII/UTF-8 conversion utilities

## Installation

Build and tested with Python 3.11.

Install dependencies:

```bash
pip install pydantic pytest requests
```

For LLM chat features (optional):

```bash
pip install langchain langchain-openai langchain-community
```

Or if using a virtual environment:

```bash
source venv/bin/activate
pip install pydantic pytest requests
pip install langchain langchain-openai langchain-community  # Optional
```

## Running the Server

Start the server on default port 6464:

```bash
python cloud.py
```

Custom host and port:

```bash
python cloud.py --host 0.0.0.0 --port 8080
```

Enable debug logging:

```bash
python cloud.py --debug
```

## Testing

Run all tests:

```bash
pytest -v
```

Run specific test suites:

```bash
pytest test_cloud.py -v      # Core server tests
pytest test_handlers.py -v   # Handler tests
```

Run test client in interactive mode:

```bash
python test_client.py
```

Run test client in demo mode:

```bash
python test_client.py --demo
```

Connect to a different server:

```bash
python test_client.py --host 192.168.1.100 --port 8080
```

## Request Handlers

The server uses a dispatcher system to route text input commands to specialized handlers:

### Chat Handler (I: prefix)

Sends queries to an LLM for conversational AI assistance.

**Usage:** `I: <your question>`

**Examples:**
- `I: what is the commodore 64?`
- `I: how do I use peek and poke?`
- `I: explain machine code`

**Configuration:**
- Requires `OPENAI_API_KEY` environment variable
- Optional `CONTEXT7_API_KEY` for enhanced documentation access
- Optional `SERPAPI_API_KEY` and `GOOGLE_CSE_ID` for web search

### Help Handler (help prefix)

Provides help on available commands.

**Usage:** `help [topic]`

**Examples:**
- `help` - Show general help
- `help chat` - Help on chat command
- `help python` - Help on Python eval

**Available topics:** chat, python, csdb, commands

### Python Eval Handler (? prefix)

Evaluates Python expressions safely.

**Usage:** `? <expression>`

**Examples:**
- `? 2 + 2` - Basic math
- `? hex(49152)` - Convert to hex
- `? sqrt(16)` - Math functions
- `? bin(255)` - Convert to binary

**Security:** Only safe built-in functions and math operations are allowed.

### CSDB Handler (c: prefix)

Queries the csdb.dk database for C64 scene information.

**Usage:** `c: <query>`

**Examples:**
- `c: release 12345` - Get release info
- `c: group 678` - Get group info
- `c: scener 999` - Get scener info

**Note:** Currently requires specific ID numbers. Find IDs by browsing csdb.dk.

## Communication Protocol

### Client → Server

All commands start with magic bytes `$FE $FF`:

**Command $01 - Keypress:**
```
[FE FF] [01] [PETSCII_CODE] [MODIFIER_FLAGS]
```

Modifier flags:
- Bit 0: Shift
- Bit 1: Ctrl
- Bit 2: Commodore

**Command $02 - Text Input:**
```
[FE FF] [02] [PETSCII_TEXT...] [00]
```

### Server → Client

All responses start with magic bytes `$FE $FF`:

**Response Format:**
```
[FE FF] [RESPONSE_TYPE] [DATA...]
```

Response types:
- `$01` - PETSCII null-terminated string
- `$02` - Mix of commands and screen codes
- `$03` - mText format (see docs/mtext.md)

## PETSCII Conversion

The server uses PETSCII natively for internal processing. Conversion to/from UTF-8 only happens when communicating with external APIs.

**PETSCII ↔ ASCII Mapping:**
- ASCII `$41-$5A` (A-Z) ↔ PETSCII `$C1-$DA`
- ASCII `$61-$7A` (a-z) ↔ PETSCII `$41-$5A`
- Other characters map directly

## Test Client Usage

### Interactive Mode

```
> k a          # Send keypress 'a'
> ks A         # Send keypress 'A' with Shift
> kc c         # Send keypress 'c' with Ctrl
> t hello      # Send text "hello"
> q            # Quit
```

### Demo Mode

Runs predefined test commands:

```bash
python test_client.py --demo
```

## Architecture

**C64Server:**
- Manages TCP connections on configurable host/port
- Handles multiple concurrent clients
- Delegates command processing to CommandHandler

**CommandHandler:**
- Parses incoming packets and validates magic bytes
- Processes keypress and text input commands
- Generates appropriate responses
- Logs all activity for debugging

**Petscii:**
- Converts between PETSCII and ASCII/UTF-8
- Used when interfacing with external APIs
- Maintains character fidelity for C64 communication

## Development

Follow TDD approach:
1. Write tests first in `test_cloud.py`
2. Implement features in `cloud.py`
3. Run tests: `pytest test_cloud.py -v`
4. Test manually with `test_client.py`

## Future Enhancements

- Implement actual command handlers (DIR, LOAD, etc.)
- Add mText format support
- Integrate with web APIs (Wikipedia, weather, etc.)
- Add authentication/security
- Support for multiple simultaneous C64 clients
- Cloud deployment instructions (AWS Lambda, Google Cloud Functions, etc.)
