#import "utils.asm"
#import "parser_functions.asm"

// -----------------------------------------------------------------------------
// Memory Dump Command
// -----------------------------------------------------------------------------
// Purpose:
//   Displays a memory dump in both hexadecimal and ASCII formats, allowing editing.
// Usage:
//   Maaaa [eeee]
//     - 'M' starts the memory dump command.
//     - 'aaaa' is the start address.
//     - 'eeee' is the optional end address.
// Notes:
//   - Both hex and ASCII are shown for each memory line.
// <memory_dump_command> ::= "M" [ <address> [ <end_address> ] ]


// display memory [M]
cmd_m:
    // Check for optional address
    jsr parse_address
    bcc !+
    // Error parsing filename, handle error
    lda #$03  // TODO error parsing address, print error message
    sta $d020
    jmp DSPLYM  // jump to parser completion handler in parser.asm
!:
    cmp #$00
    beq DSPLYM   // go without address if none provided
    // Address provided
m_address_from:
    inc $d020
    lda SAVX
    sta TMP0
    sta TMP2          // low byte of start address
    lda SAVY
    sta TMP0+1
    sta TMP2+1        // high byte of start address

    // list the memory
    // Input: TMP2/TMP2+1 = start address
DSPLYM:
    // bcs DSPM11          // start from previous end addr if no address given
    // jsr GETPAR          // get end address in TMP0
    // bcc DSMNEW          // did user specify one?
DSPM11:
    lda #$0B            // if not, show 12 lines by default
    sta TMP0
    bne DSPBYT          // always true, but bne uses 1 byte less than jmp
DSMNEW:
    jsr SUB12           // end addr given, calc bytes between start and end
    bcc MERROR          // error if start is after end
    ldx #3              // divide by 8 (shift right 3 times)
DSPM01:
    lsr TMP0+1
    ror TMP0
    dex 
    bne DSPM01
DSPBYT:
    jsr STOP            // check for stop key
    beq DSPMX           // exit early if pressed
    jsr DISPMEM         // display 1 line containing 8 bytes
    lda #8              // increase start address by 8 bytes
    jsr BUMPAD2
    jsr SUBA1           // decrement line counter
    bcs DSPBYT          // show another line until it's < 0
DSPMX:
    CommandDone()      // back to main loop
MERROR:
    jmp ERROR           // handle error

    CommandDone()      // jump to parser completion handler in parser.asm
