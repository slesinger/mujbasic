#import "utils.asm"

// -----------------------------------------------------------------------------
// Help Command
// -----------------------------------------------------------------------------
// Purpose:
//   Displays help information for available commands.
// Usage:
//   HELP
//     - 'HELP' shows the help information.
// Notes:
//   - Useful for debugging and code analysis.
// <help_command> ::= "HELP"

cmd_help:
    ldy #MSG_HELP - MSGBAS    // display headers
    jsr SNDCLR


    lda #$32
    // execute actual job

    CommandDone()  // jump to parser completion handler in parser.asm
