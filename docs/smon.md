
# SMON

SMON is one of the best (if not the best) machine language monitors for the Commodore 64. It features a wide range of functions to display and modify (including an assembler) the C64 memory. Furthermore, it permits tracing through programs in single step. There is even a small disk monitor included.

SMON requires 4 KByte of RAM for its program code and local variables. To provide greater flexibility, Power64 supplies three versions of SMON, that differ only in terms of the memory range that they occupy in the C64 memory:

- **SMON($C000)** uses the memory from `$C000` to `$CFFF` and must be started with `SYS 49152`. This part of the RAM is not used by BASIC, and is therefore the most popular (and recommended) place for tools like SMON.
- If you want to use SMON together with another tool that blocks this space, you can use one of the two other versions:
	- **SMON($9000)** [`SYS 36864`]
	- **SMON($8000)** [`SYS 32768`]

Note: These versions use some of the memory (4 KByte for SMON($9000) and 8 KByte for SMON($8000)) that would otherwise be available for BASIC. The pointer to the top of the available RAM (`$37/$38`) is automatically adjusted when these versions of SMON are loaded, to prevent BASIC from overwriting SMON with variables.

---

## SMON Commands

### A xxxx — Assemble

Assemble code starting at `xxxx`. It is possible to use markers (a simple form of symbolic labels) in the form `Mxx`. A single `X` ends the assembly.

### B xxxx yyyy — BASIC Data

Create BASIC Data lines for the memory contents from `xxxx` to `yyyy`.  
Note: Line-numbers start with 32000 (defined in `$C087/$C088`). The maximal length of a created BASIC line is usually 80 characters (the maximal length that can be edited with the C64 BASIC editor). If you want shorter lines (e.g. 72 characters, that are usually the limit for emails and news-postings) set `$C9AE` to the desired length -7 (e.g. 65 for 72 characters).

### C xxxx yyyy zzzz aaaa bbbb — Convert Program

The memory block from `xxxx` to `yyyy` is moved to `zzzz`. All absolute addresses in the code between `aaaa` and `bbbb` that pointed into the moved range are adjusted.

### D xxxx (yyyy) — Disassemble

Disassemble the program starting at `xxxx` (and ending at `yyyy`). Changes to the code are possible by overwriting the opcodes.

### F aa bb cc ..., xxxx yyyy — Find Byte

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

### I xx — I/O Device

Select the I/O Device for Load and Save. Common values for `xx` are `01` for Tape and `08` to `0B` for Floppy.

### K xxxx (yyyy) — Kontrolle

Display the memory contents from `xxxx` to `yyyy` as ASCII-characters. Changes are possible by overwriting the characters.

### L "filename" (xxxx) — Load

Load a file from the standard I/O device (see command I) at the standard address or `xxxx`.

### M xxxx (yyyy) — Memory Dump

Display the memory contents from `xxxx` to `yyyy` as hex-values and ASCII-characters. Changes are possible by overwriting the hex-values.

### O xxxx yyyy zz — Occupy

Fill the memory range `xxxx` to `yyyy` with the value `zz`.

### P xx — Printer

Select the device number for the printer. Valid values for `xx` are `04` and `05`. To send the output of a command to the printer, the mnemonic for that command must be written in upper case.

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

### X — Exit SMON

### # num — Convert Decimal

The decimal number `num` is converted to hexadecimal notation. If `num` is an 8-bit number, then the binary form is also displayed.

### $ xxxx — Convert Hexadecimal

The hexadecimal number `xxxx` is converted to decimal notation. If `xxxx` is an 8-bit number, then the binary form is also displayed.

### % xxxxxxxx — Convert Binary

The (8 Bit!) binary number `xxxxxxxx` is converted to decimal and hexadecimal notation.

### ? xxxx + yyyy — Hexadecimal Addition or Subtraction

Two 16 Bit hexadecimal numbers are added or subtracted.

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
