# C64 Cloud Server - Quick Reference

## Command Syntax

| Command | Description | Example |
|---------|-------------|---------|
| `I: <question>` | Ask AI assistant | `I: what is peek and poke?` |
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

```bash
# Run all tests
pytest -v

# Run example demo
python example_dispatcher.py

# Test with client simulator
python test_client.py
```

## Server Startup

```bash
# Default (port 6464)
python cloud.py

# Custom port
python cloud.py --port 8080

# Debug mode
python cloud.py --debug
```

## File Structure

```
cloud/
├── cloud.py                    # Main server
├── base_handler.py             # Handler base class
├── chat_handler.py             # AI chat (I:)
├── help_handler.py             # Help system
├── python_eval_handler.py      # Python eval (?)
├── csdb_handler.py             # CSDB queries (c:)
├── test_cloud.py               # Core tests
├── test_handlers.py            # Handler tests
├── test_client.py              # Test client
├── example_dispatcher.py       # Demo script
└── README_CLOUD.md             # Full documentation
```

## Security Notes

- Python eval is sandboxed (no file/network access)
- No module imports allowed in eval
- All handlers run in same process
- API keys stored in environment variables (not in code)

## Troubleshooting

### "Chat service unavailable"
- Install LangChain: `pip install langchain langchain-openai`
- Set API key: `export OPENAI_API_KEY="your-key"`

### "CSDB network error"
- Check internet connection
- Verify csdb.dk is accessible
- Try again later (rate limiting)

### Python eval errors
- Check syntax: `? 2+2` not `?2 +2`
- Use allowed functions only
- See `help python` for function list
