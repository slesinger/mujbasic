#import "constants.asm"
#import "utils.asm"

// -----------------------------------------------------------------------------
// Register Command
// -----------------------------------------------------------------------------
// Purpose:
//   Displays and allows editing of CPU registers (A, X, Y, SP, PC, flags).
// Usage:
//   R
//     - 'R' shows the current register values and allows editing.
// Notes:
//   - Useful for debugging and code analysis.
// <register_command> ::= "R"

cmd_r:
// display registers [R]
DSPLYR:
    ldy #MSG2-MSGBAS    // display headers
    jsr SNDCLR
    lda #$3B            // prefix registers with "; " to allow editing
    jsr CHROUT
    lda #$20
    jsr CHROUT
    lda PCH             // print 2-byte program counter
    jsr WRTWO
    ldy #1              // start 1 byte after PC high byte
DISJ:
    lda PCH,Y           // loop through rest of the registers
    jsr WRBYTE          // print 1-byte register value, write two hex digits
    iny 
    cpy #7              // there are a total of 5 registers to print
    bcc DISJ

    // new line
    lda #$0D
    jsr CHROUT
    // execute actual job
    jmp parse_done  // jump to parser completion handler in parser.asm
