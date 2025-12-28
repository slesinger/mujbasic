










### Syntax

The syntax for user commands is as follows:

see parser directory

## Prerequisites

1. **KickAssembler** - Java-based 6502 assembler
   - Download from: http://www.theweb.dk/KickAssembler/
   - Install Java Runtime Environment (JRE) if not already installed

2. **VS Code Extension** - `Kick Assembler 8-Bit Retro Studio`

3. **VICE Emulator** (optional, for testing)
   - Download from: https://vice-emu.sourceforge.io/
   - Recommended for testing the ROM

## Building the Project

### Method 1: Using VS Code Tasks (Recommended)

1. Open `hdnsh.asm` in VS Code
2. Press `Ctrl+Shift+B` (or `Cmd+Shift+B` on Mac) to build
3. The output will be created in the `build/` directory

### Method 2: Command Line

```bash
java -jar /home/honza/projects/c64/pc-tools/kickass/KickAss.jar hdnsh.asm -o build/hdnsh.bin
```

## Running the ROM

### In VICE Emulator

To test the ROM replacement in VICE (x64sc recommended):

```bash
x64sc -basic hdnsh.bin -reu -reusize 128
```

Or use the "Build and Run in VICE" task from VS Code (requires VICE path configured in extension settings).

### On Real Hardware

1. Burn the ROM to an EPROM/EEPROM chip
2. Create a cartridge PCB with the ROM at the BASIC ROM address space
3. Insert cartridge and power on the C64

**Note:** For cartridge format, you need to create a proper CRT file with cartridge header. The current build creates a raw binary suitable for cartridge use.

## Memory Map

- **$A000-$BFFF**: BASIC ROM space (8KB) - where our code lives
- **$0400-$07E7**: Screen memory (1000 bytes)
- **$D020**: Border color register
- **$D021**: Background color register

## Expected Behavior

When the ROM is loaded:
1. Screen is cleared with spaces
2. Border color set to light blue ($0E)
3. Background color set to blue ($06)
4. The first character on screen (top-left corner) will rapidly cycle through different characters as $0400 is incremented

## Configuration

### KickAssembler Extension Settings

Make sure to configure the extension with paths to:
- KickAssembler JAR file: `kick-assembler-vscode-ext.KickAssembler.kickAssJarPath`
- VICE emulator: `kick-assembler-vscode-ext.VICE.emulatorPath`

You can set these in VS Code settings (JSON):

```json
{
    "kick-assembler-vscode-ext.KickAssembler.kickAssJarPath": "/path/to/KickAss.jar",
    "kick-assembler-vscode-ext.VICE.emulatorPath": "/path/to/x64sc"
}
```


## Technical Notes

### BASIC ROM Vectors

The BASIC ROM must provide specific vectors at the end of the ROM space ($BF80-$BFFF) for the KERNAL to properly interface with it. The current minimal version includes placeholder vectors.

### Cold Start

The C64 KERNAL jumps to $A000 on cold start (power-on or reset with ROM replacement). Our code begins execution at this address.


## Resources

- [C64 Memory Map](https://sta.c64.org/cbm64mem.html)
- [KickAssembler Documentation](http://www.theweb.dk/KickAssembler/webhelp/content/topics/introduction.html)
- [6502 Instruction Set](http://www.6502.org/tutorials/6502opcodes.html)
- [C64 Wiki](https://www.c64-wiki.com/)

## Notes

### HDN Cloud
[See cloud/README.md for details](cloud/README.md)
### Context7

/websites/theweb_dk_kickassembler_webhelp
/mist64/c64ref

# Error Parking Lot

G 080D se chova divne, G $080D je OK

BRK handler neni aktiovan, protoze se vse pak chova trochu divne.

# Ideas Parking Lot

cursor - rotating line to indicate 

hondani cloud - group chat with https://github.com/WiC64-Team/wic64-mex

vic konzoli jako screen

AI chat

AI by mela dokumentaci
  https://www.the-dreams.de/aay.html

HDN cloud zlate stranky C64 sceny, group list, 
demo list, game list, latest releases

  "Who is Hondani" pres AI

 csdb messages

 coding help codex - AI coding prgletu

 ## High-level use cases

 - Play games/demos
 - Fetch them from csdb.dk
 - Search new releases in csdb.dk,...
 - Messaging via csdb.dk
 - Chat between C64 users
 - News accumulation from various sources (csdb.dk, lemon64.com, ...)
 - Use HDN Shell documentation (with AI)
 - Develop prglets for HDN Shell
 - Develop stuff on C64U
 - Use C64 reference documentation (with AI)
 - Do daily routine tasks on C64 (reading emails, browsing web,...)
 - Use HDN Cloud applications (chat, coding help, databases, conversation tools, memory analysis, ...)
 - General AI chatting
 - Use git
 - Image search/generation and conversion to C64 graphics
 - SID Music search and playback
 - Manage files on C64U SD card
 - Manage files on HDN Cloud, share files