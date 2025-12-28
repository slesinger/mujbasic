# C64 Cloud Server - Quick Reference

## Command Syntax

| Command | Description | Example |
|---------|-------------|---------|
| `I: <question>` | Ask AI assistant | `I: what is peek and poke?` |
| `i:` | Enter Chat navigation mode | `i:` |
| `help [topic]` | Get help | `help`, `help chat` |
| `? <expression>` | Evaluate Python | `? 2 + 2`, `? hex(49152)` |
| `c:` | Enter CSDB navigation mode | `c:` |
| `cd <type>` | Change CSDB directory (release, group, scener, event, bbs, sid) | `cd group` |
| `find <text>` | Search in current CSDB directory (or all if none) | `find hondani` |
| `cd <id>` | Enter detail for item in current directory | `cd 901` |
| `pwd` | Show current CSDB path | `pwd` |

## Python Eval Functions

### Basic Math
- `+`, `-`, `*`, `/`, `//`, `%`, `**`
- `abs()`, `min()`, `max()`, `sum()`
- `divmod()`, `pow()`, `round()`

### Conversions
- `hex()` - Decimal to hex
- `bin()` - Decimal to binary
- `oct()` - Decimal to octal
- `int()`, `float()`, `str()`
- `chr()`, `ord()` - Character conversions

### Math Functions
- `sqrt()`, `pi`, `e`
- `sin()`, `cos()`, `tan()`
- `log()`, `log10()`, `exp()`
- `floor()`, `ceil()`

## Help Topics

- `help` - General help
- `help chat` - Chat/AI help
- `help python` - Python eval help
- `help csdb` - CSDB query help
- `help commands` - Command list

## Common C64 Conversions

```
? hex(49152)   # Screen memory: $C000
? hex(53280)   # Border color: $D020
? hex(53281)   # Background: $D021
? hex(54272)   # SID: $D400
? hex(65535)   # Max address: $FFFF
```

## CSDB Navigation & Queries

### Entering CSDB mode
```
c:
```
This sets CSDB as the active module for your session. All subsequent commands will be interpreted as CSDB commands until you switch modules.

### Navigation commands
```
cd <type>      # Change to a CSDB directory (group, release, scener, event, bbs, sid)
find <text>    # Search for items in the current directory (or all types if none)
cd <id>        # Enter detail for an item in the current directory (e.g. cd 901)
pwd            # Show current CSDB path (e.g. c:/group/901)
```

### Direct queries
```
c: release <id>  # Get release info by ID
c: group <id>    # Get group info by ID
c: scener <id>   # Get scener info by ID
c: event <id>    # Get event info by ID
```

### Example session
```
c:
cd group
find hondani
cd 901
pwd
```
This will:
- Enter CSDB navigation mode
- Change to the group directory
- Find all groups matching "hondani"
- Enter the group with ID 901
- Show the current path as c:/group/901

Each user/session has an independent CSDB navigation state (session id is a 2-byte integer, default 0 if not provided).

## Setup for Full Features

### Required (core functionality)
```bash
pip install requests pydantic pytest
```

### Optional (LLM chat features)
```bash
pip install langchain langchain-openai langchain-community
export OPENAI_API_KEY="your-key-here"
```

### Optional (web search in chat)
```bash
export SERPAPI_API_KEY="your-key-here"
export GOOGLE_CSE_ID="your-cse-id"
```

### Optional (documentation access)
```bash
export CONTEXT7_API_KEY="your-key-here"
```

## Testing

# C64 Cloud Server - Quick Reference

## Overview

This document describes the commands and capabilities exposed by the C64 Cloud Server in the cloud/ folder. The server accepts simple text input from a C64 client and dispatches it to handlers implemented in Python. Supported modules: chat (`I:`), help (`help`), Python eval (`?`), and CSDB navigation (`c:`).

## Command Syntax

- **I:** : Ask the AI assistant (Chat). Example: `I: what is peek and poke?`
- **help** : Show general help or a topic. Example: `help`, `help python`
- **?** : Evaluate a Python expression. Example: `? 2 + 2`, `? hex(49152)`
- **c:** : Enter CSDB navigation mode or perform direct CSDB queries. Example: `c:` or `c: release 901`

Notes:
- Commands are matched in priority order by handlers registered in `cloud.py` (Help, PythonEval, Chat, CSDB).
- Handlers expect plain UTF-8 text (the server converts PETSCII input from the C64 into UTF-8).

## Python Eval (`?`)

Available functions and behavior (see `python_eval_handler.py`):
- Safe builtins: `abs`, `bin`, `bool`, `chr`, `divmod`, `float`, `hex`, `int`, `len`, `max`, `min`, `oct`, `ord`, `pow`, `round`, `str`, `sum`
- Math bindings: `pi`, `e`, `sqrt`, `sin`, `cos`, `tan`, `floor`, `ceil`, `log`, `log10`, `exp`
- Execution runs with `__builtins__` blocked and only the above names exposed to the expression environment.
- Results formatting:
	- `int` results in range 0..65535 are shown with hex (e.g. `123 ($007B)`).
	- Floats are shown to 6 decimal places trimmed of trailing zeros.
	- Strings are quoted in the response.

Security notes:
- No imports or arbitrary attribute access are provided by the safe namespace.
- The evaluator is intended for short expressions only.

## Help (`help`)

- `help` with no argument returns the static help text defined in `HELP_TEXT`.
- `help <topic>` returns one of the static `HELP_TOPICS` entries (e.g., `chat`, `python`, `csdb`, `commands`).
- If Azure OpenAI configuration is present and LangChain is installed, the `HelpHandler` may attempt to use an LLM to find or synthesize topic content.

## Chat (`I:`)

- `I: <message>` forwards the message to `ChatHandler`.
- If Azure OpenAI credentials (and langchain packages) are present, the handler uses `AzureChatOpenAI` to query the model using the `CHAT_SYSTEM_PROMPT` system message.
- If LLM is not available, a short fallback message is returned: "Chat service is currently unavailable. Please check API configuration.".

## CSDB Navigation & Queries (`c:`)

The CSDB module provides both direct queries and a navigational mode with per-session state. Key points (see `csdb_handler.py` and parser modules):

- `c: <query>` runs a one-shot query (for example `c: release 901` or `c: find hondani`).
- Sending `c:` by itself switches the session into CSDB navigation mode. Subsequent text commands are interpreted by the CSDB handler until a different module is selected.
- Supported navigation commands (when in `c` mode):
	- `cd <type>` where `<type>` can be `release`, `group`, `scener`, `event`, `bbs`, `sid` — sets the active directory type.
	- `find <text>` searches the selected directory (or all types if none selected) using CSDB search pages.
	- `cd <id>` enters the detail view for the item with numeric id (e.g., `cd 901`).
	- `pwd` shows the current CSDB path for the session (e.g., `c:/group/901`).
	- `cp <file-pattern>` attempts to copy files from a release or zip to `/tmp/c64cloud` (server-side temporary area).
	- `ls` / listing commands are supported implicitly when entering a directory or opening a zip (see handlers for formatting).

Parser utilities included in `cloud/`:
- `csdb_search_parser.py` — parses CSDB search/find HTML into structured results (releases, groups, sceners, etc.).
- `csdb_release_parser.py` — parses release detail pages (files, groups, dates).
- `csdb_group_parser.py` — parses group detail pages (members, releases).

Operational notes:
- The handler uses HTTP requests to `https://csdb.dk/` for search and detail pages.
- File downloads (release files / zip) are saved under `/tmp/c64cloud` and may be extracted when needed.

## Example CSDB Session

```
c:
cd group
find hondani
cd 901
pwd
cp *.d64
```

## Setup & Dependencies

Install core runtime dependencies:

```bash
pip install -r cloud/requirements.txt
```

If `requirements.txt` is missing, install the core libs manually:

```bash
pip install requests pydantic beautifulsoup4 pytest
```

Optional (LLM/chat features):

```bash
pip install langchain langchain-openai langchain-google
export AZURE_OPENAI_API_KEY=...           # or other provider variables used by handlers
export AZURE_OPENAI_ENDPOINT=...
export AZURE_OPENAI_DEPLOYMENT_NAME=...
```

Optional (Google web search for ChatHandler tools):

```bash
export GOOGLE_API_KEY=...
export GOOGLE_CSE_ID=...
```

## Running the Server

Start the server from the `cloud/` directory:

```bash
python cloud.py          # default: host 0.0.0.0 port 6464
python cloud.py --port 8080
python cloud.py --debug  # enable debug logging
```

There are VS Code tasks configured in the repository root for building the C64 assembly and running VICE; those are unrelated to the Python server.

## Tests & Examples

Run unit tests from the project root:

```bash
pytest -v
```

Run the example dispatcher or client simulator:

```bash
python example_dispatcher.py
python test_client.py
```

## File Layout (relevant files)

```
cloud/
├── cloud.py
├── base_handler.py
├── chat_handler.py
├── help_handler.py
├── python_eval_handler.py
├── csdb_handler.py
├── csdb_search_parser.py
├── csdb_release_parser.py
├── csdb_group_parser.py
├── example_dispatcher.py
├── test_client.py
├── test_cloud.py
├── test_handlers.py
└── requirements.txt (optional)
```

## Security Notes

- The Python evaluator restricts `__builtins__` and only exposes a small safe namespace.
- Handlers may perform network I/O (CSDB queries, optional LLM calls) — configure environment and credentials carefully.
- Downloaded files are written to `/tmp/c64cloud` when using `cp` or extracting zip contents.

## Troubleshooting

- "Chat service is unavailable": ensure Azure OpenAI environment variables and `langchain` packages are installed.
- "CSDB network error": verify network access to `https://csdb.dk` and check for rate limits.
- Python eval errors: check expression syntax and use allowed functions only.
