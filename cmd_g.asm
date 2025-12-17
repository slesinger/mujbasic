#import "constants.asm"
#import "utils.asm"
#import "parser_functions.asm"
// -----------------------------------------------------------------------------
// Go Command
// -----------------------------------------------------------------------------
// Purpose:
//   Execute programm at <address> and update CPU registers (A, X, Y, SP, PC, flags).
// Usage:
//   G <address>
// Notes:
//   - Useful for debugging and code analysis.
// <go_command> ::= "G" <address>
// TODO test this after we can load some prg to mem
cmd_g:
    // Check for required address
    jsr parse_address
    bcc !+
    // Error parsing filename, handle error
    lda #$03  // TODO error parsing address, print error message
    sta $d020
    CommandDone()  // jump to parser completion handler in parser.asm
!:
    bne !+
    // No address provided, handle error
    lda #$04  // TODO no address provided, print error message
    sta $d020
    CommandDone()  // jump to parser completion handler in parser.asm
!:
    lda SAVY           // check if high byte is not 0 - indicates no address has been read
    bne !+
    lda #$05
    sta $d020         // TODO address in zero page not allowed, print error message
    CommandDone()    // jump to parser completion handler in parser.asm
!:
    ParsingInputsDone() // finish parsing input line
    // Address parsed successfully, JMP to it
    jmp run_address

// copy TMP0 to PC
COPY1P:
    bcs CPY1PX          // do nothing if parameter is empty
    lda TMP0            // copy low byte
    ldy TMP0+1          // copy high byte
    sta PCL
    sty PCH
CPY1PX:
    rts 
