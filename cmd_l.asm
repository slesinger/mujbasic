#import "floppy.asm"
// -----------------------------------------------------------------------------
// Load Command
// -----------------------------------------------------------------------------
// Purpose:
//   Loads a file from the selected device into memory at the specified address (optional).
// Usage:
//   l "filename" [aaaa]
//     - 'l' starts the load command.
//     - 'filename' is the name of the file to load (in quotes).
//     - 'aaaa' is the optional address to load the file into.
// Notes:
//   - If no address is given, the file is loaded to its default location.
// <load_command> ::= "l" <ws> <file_or_path> [ <ws> <address> ]


cmd_l:
    jsr LoadFile
    jmp parse_done  // jump to parser completion handler in parser.asm
