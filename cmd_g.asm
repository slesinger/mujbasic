#import "constants.asm"
#import "utils.asm"

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
    ldx SP              // load stack pointer from memory
    txs                 // save in SP register
    jsr COPY1P          // copy provided address to PC
    sei                 // disable interrupts
    lda PCH             // push PC high byte on stack
    pha
    lda PCL             // push PC low byte on stack
    pha
    lda SR              // push status byte on stack
    pha
    lda ACC             // load accumulator from memory
    ldx XR              // load X from memory
    ldy YR              // load Y from memory
    rti                 // return from interrupt (pops PC and SR)

    // jmp parse_done  // jump to parser completion handler in parser.asm

// copy TMP0 to PC
COPY1P:
    bcs CPY1PX          // do nothing if parameter is empty
    lda TMP0            // copy low byte
    ldy TMP0+1          // copy high byte
    sta PCL
    sty PCH
CPY1PX:
    rts 
