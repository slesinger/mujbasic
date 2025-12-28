# TODO

```
Create Ultimage cfg file
Verify installation steps
How to set cloud IP address in HDN Shell???
ngrok for testing cloud server from internet????
```

# HDN Shell - BASIC ROM Replacement for Commodore 64

_You want to pronounce HDN Shell as "Hondani Shell"_.

This project replaces the standard Commodore 64 BASIC ROM ($A000-$BFFF) with modern command line sporting new features. When the C64 is switched on, this ROM gets executed instead of the built-in BASIC interpreter. The HDN Shell provides modern command line capabilities inspired by Linux shell commands, enhancing productivity on the C64.

## Benefits for C64 Users
 
 - Simplifies frequently used commands (instead of `LOAD "*",8,1` you can just type `LS` or `DIR`),
 - Speeds up file management tasks (switching drives `#9`, copying `cp from to`, ...),
 - Use SD2IEC like device #14 (with Ultimate), including directories,
 - Command line inspired by Linux,
 - Command history,
 - Screen scrollback capability\*,
 - Integrated monitor for memory inspection,
 - Connects to HDN Cloud for extended functionality\*\*,
 - Fully open source, including cloud server code,
 - HDN Cloud can be run on your PC fully transparent privacy,
 - or use free public HDN Cloud server for easier setup,
 - Searchable manual pages\*\*,
 - AI chat\*\*,  
 - Execute python expressions\*\*,
 - All the above by keeping all the memory free for your programs.

\* Requires REU  
\*\* Requires C64 Ultimate or 1541 Ultimate cartridge with networking capabilities

## Motivation
 
 - C64 is a great hardware C64 Ultimate makes it even better,
 - These days, C64 can be used as a serious computer for \<insert your favorite reason\>,
 - Command line is powerful, that is a fact, HDN Shell brings power of command line to C64,
 - Focus on productivity, not on nostalgia,
 - HDN Shell replaces BASIC ROM and hence all C64 memory remains free for your usage,
 - BASIC is mostly only used for loading programs, hence you will not miss it much,
 - Who wants to program in BASIC can plug in a cartridge with BASIC,
 - Mankind got impatient, HDN Shell uses fast methods for injecting programs into memory,
 - Use cloud services with C64, network like a modern computer.
 - See all the features HDN Shell brings to your C64.

 ## Future Features

 - Have multiple command line sessions (virtual consoles) and switch between them like in Linux (C=+1, C=+2, ...),
 - Allow for copy/paste on the screen, (maybe between cloud and C64 also?), 
 - Write your own program in the cloud and use it on the C64,
 - prglets support - relocatable small residential programs
 - SID/MOD background music playback,
 - Provide a simple file editor (like [speedscript](https://github.com/gillham/speedscript)),

## How do I Install it?

The sweet spot is to use C64 Ultimate or 1541 Ultimate cartridge with networking capabilities. However, if you do no have one there are other options. See below.

In a nutshell, for full functionality you need to:

1. Set BASIC ROM in the Ultimate menu.
2. Enable REU (recommended size 16MB) in the Ultimate menu.
3. Connect your Ultimate to the network (Ethernet or WiFi).

### Using C64 Ultimate or 1541 Ultimate

#### BASIC ROM Replacement

Download the latest `hdnsh.bin` from the [Releases](https://github.com/slesinger/hdnshell/releases) page.

...

### Alternative Options (without C64 Ultimate)

...

### How do I Verify it Works?

...

## User Manual

You can type ```HELP``` in the command line to get a list of available commands. You can also get help on particular topic with ```HELP <command>``` or ```HELP <whatever is difficult for you>```.

Or, read the [User Manual](docs/user_manual.md).

## License

This project is free to use and modify for educational and personal purposes.

## Author

[Honza](https://csdb.dk/scener/?id=2588) with support of the [Hondani](https://csdb.dk/group/?id=901) gang.

Created with KickAssembler for the Commodore 64

