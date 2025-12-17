#import "constants.asm"
#import "utils.asm"
#import "parser_functions.asm"

// -----------------------------------------------------------------------------
// Run BASIC Program Command
// -----------------------------------------------------------------------------
// Purpose:
//   Scan BASIC program area at 0801 for $9e (SYS) and fetch the address to run.
// Usage:
//   RUN
//     - 'RUN' scans the BASIC program area at 0801 for $9e (SYS) and fetches the address to run.
// Notes:
//   - The SYS command needs to be within first 254 bytes of the BASIC program else it gives up.
cmd_run:
    // Copy BASIC prg bytes to parser input buffer for scanning and find SYS token
    ldy #0         // start at offset 0
!cpyloop:
    lda BASIC_START,y  // load byte from BASIC program area
    sta PARSER_INPUT_PTR,y
    iny          // increment Y to check next byte
    cmp #$9E     // compare with SYS token
    beq !FoundSys+  // if found, branch to FoundSys
    cpy #$4F     // check if we reached 79 bytes
    bne !cpyloop-       // if not, continue scanning
    jmp !parse_add+
!FoundSys:
    dey
    lda #KEY_PLUS
    sta PARSER_INPUT_PTR,y
    dey                      // move back one more position
    sty parser_input_cursor  // store offset BEFORE the KEY_PLUS
    iny
    iny                      // restore Y to continue copying after KEY_PLUS
    jmp !cpyloop-
    // convert decimal string to hex lo-hi address
!parse_add:
    jsr RDVAL
    ParsingInputsDone() // finish parsing input line
    lda SAVY           // check if high byte is not 0 - indicates no address has been read
    bne !+
    lda #$05
    sta $d020         // TODO address in zero page not allowed, print error message
    CommandDone()    // jump to parser completion handler in parser.asm
!:
    // all good, lets run
    jmp run_address
    // It never gets here