#import "utils.asm"

// -----------------------------------------------------------------------------
// Unknown Command
// -----------------------------------------------------------------------------
// Purpose:
//   Display error message for unknown command.
// Usage:
//   wrong usage :-)
// Notes:
//   - Does not execute any command.

cmd_unknown:

lda #$0D
jsr CHROUT

    ldy #MSG_UNKNOWN_COMMAND - MSGBAS    // display headers
    jsr SNDMSG
    CommandDone()  // jump to parser completion handler in parser.asm
