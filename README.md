# MujBASIC - Custom BASIC ROM Replacement for Commodore 64

A custom BASIC ROM replacement for the Commodore 64, written in 6502 assembly using KickAssembler. This project assumes running on Commodore Ultimate or Commodore 64 with Ultimate Cartridge for networking capabilities.

## Project Overview

This project replaces the standard Commodore 64 BASIC ROM ($A000-$BFFF) with custom code. When the C64 is switched on, this ROM gets executed instead of the built-in BASIC interpreter.

### Current Version: 0.1 (Minimal Test)

Features:
- Initialize (detects REU size, clears screen)
- Expects user input like a terminal
- Dispatch user input (see Syntax section)

### Future Plans
- Implement a simple plain text editor https://github.com/gillham/speedscript
- prglets support - relocatable small residential programs (relocation possible with hints in header and relative jumps
)
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

1. Open `mujbasic.asm` in VS Code
2. Press `Ctrl+Shift+B` (or `Cmd+Shift+B` on Mac) to build
3. The output will be created in the `build/` directory

### Method 2: Command Line

```bash
java -jar /home/honza/projects/c64/pc-tools/kickass/KickAss.jar mujbasic.asm -o build/mujbasic.bin
```

## Running the ROM

### In VICE Emulator

To test the ROM replacement in VICE (x64sc recommended):

```bash
x64sc -basic mujbasic.bin -reu -reusize 128
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

## Development Roadmap

- [x] v0.1: Minimal ROM with screen increment loop
- [ ] v0.2: Add basic text output capability
- [ ] v0.3: Implement simple command parser
- [ ] v0.4: Add tokenizer for BASH commands, will be executed remotely in Cloud via C64 Ultimate networking
- [ ] v1.0: Full interpreter replacement

## Technical Notes

### BASIC ROM Vectors

The BASIC ROM must provide specific vectors at the end of the ROM space ($BF80-$BFFF) for the KERNAL to properly interface with it. The current minimal version includes placeholder vectors.

### Cold Start

The C64 KERNAL jumps to $A000 on cold start (power-on or reset with ROM replacement). Our code begins execution at this address.

## License

This project is free to use and modify for educational and personal purposes.

## Resources

- [C64 Memory Map](https://sta.c64.org/cbm64mem.html)
- [KickAssembler Documentation](http://www.theweb.dk/KickAssembler/webhelp/content/topics/introduction.html)
- [6502 Instruction Set](http://www.6502.org/tutorials/6502opcodes.html)
- [C64 Wiki](https://www.c64-wiki.com/)

## Author

Created with KickAssembler for the Commodore 64

## Notes

### Context7

/websites/theweb_dk_kickassembler_webhelp