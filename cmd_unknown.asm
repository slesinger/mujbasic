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
    pla  // to compensate for pha in cmd parsing loop

    // set 'command unknown'
    // TODO
    lda #$30
    jmp parse_done  // jump to parser completion handler in parser.asm
