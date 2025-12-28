To BE INSERTED
IEC docs https://c64os.com/post/sd2iecdocumentation#realtimeclock
run
rU
g $080d
g 080d

# HDN Shell User Manual

HDN Shell is a replacement to C64 BASIC. The aim is to strip of mostly unused parts of BASIC, viewed as a DOS, and replace them with a mostly used features, viewed from modern perspective, while fitting into the same 8KB ROM space. The blueprint is Linux-like terminal user experience, AI enabled, utilizing C64 Ultimate and cloud computing services.

It also includes SMON, which is one of the best (if not the best) machine language monitors for the Commodore 64. It features a wide range of functions to display and modify (including an assembler) the C64 memory. Furthermore, it permits tracing through programs in single step. There is even a small disk monitor included.

---

## General Notes

```$ hexa, + decimal, % binary``` number conversion

Clip board works by pressing C=+C which will freeze the screen and let you select text with SHIFT+cursor and commiting with RETURN. Paste works by pressing C=+V which will paste from clip board to current cursor position.

Screen buffer switching is possible by pressing C=+[1,2,3,4] to switch to one of 4 screen buffers. This is useful for having multiple screens loaded in memory and switching between them quickly.

Screen memory is buffered with history. You can scroll back the screen history by pressing C=+UP and scroll forward by pressing C=+DOWN. Moving cursor up/down will move beyond boundaries of the screen will also initiate the scrolling.

## DOS Commands

```<drive number>:```  - change default device to drive number (8,9,10,11,14)

```dir```  - list files on default device

```<drive number>:dir```  - list files on specified device

```get```/```put``` files to/from REU RAM disk

```[<drive number>]load <name with wildcards> [<to address>]``` - load file from disk or tape

```[<drive number>]save "<name>" [<from address>] [<to address>]``` - save file to disk or tape

```[<drive number>]delete "<name>"``` - delete file from disk

Navigating the Ultimate storage

Directories
The CD command lets you navigate the directory structure much like you would in Linux and Windows from the command line.

// change into the root directory
CD//

// enter directory “mydir” (relative to where you are)
CD/mydir/

// enter directory “mydir” (absolute from root directory)
CD//mydir/

// navigate up one level (like the Linux cd .. command)
CD:←
You can also create directories to stay organised without the need for other tools. That’s where the MD command comes in handy:

// create directory in the current location
MD:mydir

// create directory inside another directory
MD/mydir/:otherdir

// create a directory absolute to root
MD//mydir/:otherdir
When you’re done with a directory you can delete it with RD. Note that only empty directories can be deleted, otherwise you’ll get a FILE EXISTS error:

// remove in current directory
RD:mydir

// remove directory absolute to root
RD//mydir/:otherdir
Mounting Disk Images
The CD command can also be used to mount D64/D71/D81 image files, just as if they were standard directories. The same syntax applies as with switching directories:

// mount “myimage.d64” in current directory
CD:myimage.d64

// mount “myimage.d64” in subdirectory /mydir (relative)
CD/mydir/myimage.d64

// or absolute
CD//mydir/myimage.d64

// unmount a disk image (go back SD card directory in which the image resides)
CD:←

find filename


## Memory Operations

```stash <from> <to> <name>``` - store memory block to REU
```fetch <name> <to>``` - retrieve memory block from REU
```drop <name>``` - delete memory block from REU
```stash list``` - list stored memory blocks in REU

## PRGlets Operations

PRGlets are small programs that are loaded into memory and executed on demand. The code has to be relocatable and conform to PRGlet calling conventions. They can compile on cloud on demand from high-level language (e.g. C) or assembly.

There can always be only one PRGlet loaded at a time. It can receive data from stdin and return data to stdout which is always a dedicated buffer in memory (C64 RAM is swapped out to REU to free space for stdin/out data and then swapped back to C64 RAM). You can imagine PRGlet as always available, like being on a PATH in Linux.

```prglet load "<filename>"``` - load PRGlet from disk
```prglet run <name> [args...]``` - run loaded PRGlet with optional arguments
```prglet list``` - list loaded PRGlets
```prglet unload <name>``` - unload PRGlet from memory

## Residential Programs

Residential programs are tiny programs loaded into memory and remain there for quick access. They can be used to extend the functionality of the system or provide commonly used utilities. Multiple residential programs can be loaded simultaneously. Residential can handle exution from an interrupt on every frame.

```resident load "<filename>"``` - load a program to stay resident in memory
```resident list``` - list resident programs
```resident unload <name>``` - unload resident program from memory

## Other Commands

```i:<utterance>```  - sends the utterance to the cloud AI service (requires REU), AI replies as ```AI:<response>```

Enter portal like browser (see WiC64, SideKick64 projects), it has laready defined communication format. Thin applications can be written.

## Python Scripting

Because BASIC was stripped from the ROM, a Python scripting is made available for limited scripting. It is physically executed in the cloud compute. 

### Executing a command line command

Any command that is not recognized is considered a Python instruction. For example, to print "Hello, World!" to the console, you can simply type:

```print("Hello, World!")```

First, the C64 memory is sent for reference to the cloud, then the command is executed, and finally, any output is returned to the C64 console.

## SMON Commands

### A xxxx — Assemble

Assemble code starting at `xxxx`. It is possible to use markers (a simple form of symbolic labels) in the form `Mxx`. A single `X` ends the assembly.

### C xxxx yyyy zzzz aaaa bbbb — Convert Program

The memory block from `xxxx` to `yyyy` is moved to `zzzz`. All absolute addresses in the code between `aaaa` and `bbbb` that pointed into the moved range are adjusted.

### D xxxx (yyyy) — Disassemble

Disassemble the program starting at `xxxx` (and ending at `yyyy`). Changes to the code are possible by overwriting the opcodes.

### F aa bb cc ..., xxxx yyyy — Find Bytes

Find all occurrences of the byte sequence `aa bb cc ...` in the memory range `xxxx` to `yyyy`.  
It is possible to specify some nybbles of the search pattern as don't-care by using the wild card `*`.

> **Note:** Unlike most other SMON-commands, the Find commands are very picky about syntax. There must be no space between the command name and the arguments to be found (exception: the Find Byte command requires exactly one space), and a comma before the range.

#### FAaaaa, xxxx yyyy — Find Absolute Address

Find all references to the absolute address `aaaa` within the memory range `xxxx` to `yyyy`.  
Note that there is no space between `FA` and `aaaa`.

#### FRaaaa, xxxx yyyy — Find Relative

Find branch statements that point to address `aaaa` within the memory range `xxxx` to `yyyy`.  
Note that there is no space between `FR` and `aaaa`.

#### FTxxxx yyyy — Find Table

Find all tables in the memory range from `xxxx` to `yyyy`. SMON defines a table as any information that cannot be disassembled.

#### FZaa, xxxx yyyy — Find Zero-Page

Find all references to the zero-page address `aa` within the memory range `xxxx` to `yyyy`.  
Note that there is no space between `FZ` and `aa`.

#### FIaa, xxxx yyyy — Find Immediate

Find all statements in the memory range from `xxxx` to `yyyy` that use `aa` as immediate operand.  
Note that there is no space between `FI` and `aa`.

### G (xxxx) — Go

Execute the machine program at `xxxx` or the current PC. If the code ends with `RTS`, SMON is terminated. To jump back to SMON after the code is executed, the program must end with `BRK`.

### L "filename" (xxxx) — Load

Load a file from the standard I/O device (see command I) at the standard address or `xxxx`.

### M xxxx (yyyy) — Memory Dump

Display the memory contents from `xxxx` to `yyyy` as hex-values and ASCII-characters. Changes are possible by overwriting the hex-values.

### O xxxx yyyy zz — Occupy

Fill the memory range `xxxx` to `yyyy` with the value `zz`.

### P xxxx yyyy aaaa ... — Copy Bytes

Copy the bytes from the memory range `xxxx` to `yyyy` to a new location starting at `aaaa`.

### R — Register

Display the contents of the CPU registers. Changes are possible by overwriting the values.

### S ("filename" xxxx yyyy) — Save

Save the memory contents from `xxxx` to `yyyy` to a file. If the file has been loaded using the command L then the parameters for save are optional.

### V xxxx yyyy zzzz aaaa bbbb — Move Addresses

All absolute addresses in the code between `aaaa` and `bbbb` that pointed into the range `xxxx` to `yyyy` are adjusted to point into the range starting at `zzzz`.

### W xxxx yyyy zzzz — Write

Copy the memory contents between `xxxx` and `yyyy` to `zzzz`. No address or other transformations are performed. Works correctly even if source and destination range overlap.

### = xxxx yyyy — Check Equality

The memory ranges starting at `xxxx` and `yyyy` are compared for equality. The address of the first different byte is displayed.

---

## Other Commands

### # num — Convert Decimal

The decimal number `num` is converted to hexadecimal notation. If `num` is an 8-bit number, then the binary form is also displayed.

### $ xxxx — Convert Hexadecimal

The hexadecimal number `xxxx` is converted to decimal notation. If `xxxx` is an 8-bit number, then the binary form is also displayed.

### % xxxxxxxx — Convert Binary

The (8 Bit!) binary number `xxxxxxxx` is converted to decimal and hexadecimal notation.

---

## Disk Monitor Commands

### Z — Start Disk Monitor (Equivalent Command: H)

SMON features a built-in disk monitor for floppy disk #8. To avoid confusion in terms of command names, the disk monitor must be explicitly started and terminated. While SMON is in disk monitor mode, only the following commands are available.

> **Note:** It is not possible to examine a device other than a floppy disk (i.e. not a folder of a Mac hard disk or a tape) mounted on drive #8.

- **R (tt ss) — Read Sector**  
	Read track `tt` sector `ss` into memory. If `tt` and `ss` are missing, the next logical (not physical!) sector is read.

- **W (tt ss) — Write Sector**  
	Write track `tt` sector `ss` to disk. If `tt` and `ss` are missing, the parameters from the last Read Sector command are used.

- **M — Memory Dump**  
	Display the disk sector in memory on the screen. The Shift-keys can be used to interrupt/continue the display of data.

- **@ — Floppy Error Status**  
	Displays the current Floppy Error Message. If no error occurred, then no message is printed (i.e. the message `00, OK,00,00` is suppressed).

- **X — Exit the Disk-Monitor / Return to SMON proper.**

---
