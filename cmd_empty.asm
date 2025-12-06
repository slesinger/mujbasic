#import "constants.asm"
// -----------------------------------------------------------------------------
// No Command
// -----------------------------------------------------------------------------
// Purpose:
//   No error, just jump to next input line.
// Usage:
//   <return>
// Notes:
//   - Does not execute any command.

cmd_empty:
    // execute empty command (just ENTER)
    CommandDone()  // jump to parser completion handler in parser.asm
