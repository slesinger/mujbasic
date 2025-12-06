#import "parser_functions.asm"
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
    // Parse mandatory filename
    jsr parse_file_or_path
    bcc !+
    // Error parsing filename, handle error
    lda #RED  // TODO wrong filename, print error message
    sta $d020
    CommandDone()  // jump to parser completion handler in parser.asm

!:
    // Check for optional address
    jsr parse_address
    bcc !+
    // Error parsing filename, handle error
    lda #CYAN  // TODO error parsing address, print error message
    sta $d020
!:
    ParsingInputsDone() // finish parsing input line

    jsr load_file
    CommandDone()  // jump to parser completion handler in parser.asm
