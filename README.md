# Hondani Shell - Custom BASIC ROM Replacement for Commodore 64

This project replaces the standard Commodore 64 BASIC ROM ($A000-$BFFF) with custom code. When the C64 is switched on, this ROM gets executed instead of the built-in BASIC interpreter. The HDN Shell provides modern command line capabilities inspired by Linux shell commands, enhancing productivity on the C64.

### Motivation
 - C64 is great hardware. It received wonderful update with C64 Ultimate,
 - C64 can be used as a serious computer even these days. <your favorite reason goes here>,
 - Command line is very powerful, and yes, you can find some inspiration in Linux shell which is not so bad in the end :-),
 - HDN Shell brings power of command line to C64,
 - HDN Shell replaces BASIC ROM and hence
 - all C64 memory remains free for your usage.
 - BASIC is mostly only used for loading programs, hence you will not miss it much,
 - Who wants to program in BASIC can plug in a cartridge with BASIC,
 - See all the features HDN Shell brings to your C64.

 ### Features
 - Focus on productivity :-)
 - Abbreviated commands (e.g., `L` for `LOAD`, `LL` for `Long Directory List`),
 - Commands inspired by Linux shell commands (e.g., `LS`, `LL`, `RM`, `MV`, `CP`),
 - Command line history (use UP/DOWN arrows to navigate),
 - Scroll back the screen like page up/page down (use F1/F7 keys),
 - Integrated monitor to inspect memory (e.g. `M`, `G`),
 - More to come once Commodore will deliver my C64 Ultimate :-)
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

## Development Roadmap

- [x] v0.1: Minimal ROM with screen increment loop
- [ ] v0.2: Add basic text output capability
- [ ] v0.3: Implement simple command parser
- [ ] v0.4: Add tokenizer for BASH commands, will be executed remotely in HDN Cloud via C64 Ultimate networking
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

[Honza](https://csdb.dk/scener/?id=2588) of [Hondani](https://csdb.dk/group/?id=901)

Created with KickAssembler for the Commodore 64

## Notes

### Context7

/websites/theweb_dk_kickassembler_webhelp
/mist64/c64ref

# Error Parking Lot

G 080D se chova divne, G $080D je OK

BRK handler neni aktiovan, protoze se vse pak chova trochu divne.

# Ideas Parking Lot

cursor - rotating line to indicate 

hondani cloud - group chat

vic konzoli jako screen

AI chat

AI by mela dokumentaci

HDN cloud zlate stranky C64 sceny, group list, 
demo list, game list, latest releases

  "Who is Hondani" pres AI

 csdb messages

 coding help codex - AI coding prgletu
