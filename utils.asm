#importonce 
#import "constants.asm"

// print single hex nibble in A (0..15) as ASCII to screen via CHROUT
print_nibble:
    cmp #10
    bcc pn_digit
    // A >= 10 -> 'A'..'F'
    clc
    adc #55             // 10 + 55 = 65 'A'
    jmp pn_out
pn_digit:
    clc
    adc #48             // 0 -> '0'
pn_out:
    jsr $FFD2
    rts

// print address
SHOWAD:
    lda TMP2
    ldx TMP2+1

WRADDR:
    pha                 // save low byte
    txa                 // put high byte in A
    jsr WRTWO           // output high byte
    pla                 // restore low byte

WRBYTE:
    jsr WRTWO           // output byte in A

SPACE:
    lda #$20            // output space
    bne FLIP

CHOUT:
    cmp #$0D            // output char with special handling of CR
    bne FLIP
CRLF:
    lda #$0D            // load CR in A
    bit $13             // check default channel
    bpl FLIP            // if high bit is clear output CR only
    jsr CHROUT          // otherwise output CR+LF
    lda #$0A            // output LF
FLIP:
    jmp CHROUT

FRESH:
    jsr CRLF            // output CR
    lda #$20            // load space in A
    jsr CHROUT
    jmp SNCLR

WRTWO:
    stx SAVX            // save X
    jsr ASCTWO          // get hex chars for byte in X (lower) and A (upper)
    jsr CHROUT          // output upper nybble
    txa                 // transfer lower to A
    ldx SAVX            // restore X
    jmp CHROUT          // output lower nybble

// convert byte in A to hex digits
ASCTWO:
    pha                 // save byte
    jsr ASCII           // do low nybble
    tax                 // save in X
    pla                 // restore byte
    lsr                 // shift upper nybble down
    lsr  
    lsr  
    lsr  

// convert low nybble in A to hex digit
ASCII:
    and #$0F            // clear upper nibble
    cmp #$0A            // if less than A, skip next step
    bcc ASC1
    adc #6              // skip ascii chars between 9 and A
ASC1:
    adc #$30            // add ascii char 0 to value
    rts

// print and clear routines
// CLINE:
//     jsr CRLF            // send CR+LF
//     jmp SNCLR           // clear line
SNDCLR:
    jsr SNDMSG
SNCLR:
    ldy #$28            // loop 40 times
SNCLP:
    lda #$20            // output space character
    jsr CHROUT
    lda #$14            // output delete character
    jsr CHROUT
    dey
    bne SNCLP
    rts

// display message from table
SNDMSG:
    lda MSGBAS,Y        // Y contains offset in msg table
    php
    and #$7f            // strip high bit before output
    jsr CHOUT
    iny
    plp
    bpl SNDMSG          // loop until high bit is set
    rts

// message table; last character has high bit set
MSGBAS:
MSG2:
    .text "   PC  SR AC XR YR SP   V0.1"  // header for registers
    .byte KEY_RETURN, $80    // end of message marker
MSG_UNKNOWN_COMMAND:
    .text "COMMAND NOT FOUND"
    .byte KEY_RETURN, $80
MSG_HELP:
    .text "AVAILABLE COMMANDS:"
    .byte KEY_RETURN
    .text " HELP - DISPLAY THIS HELP MESSAGE"
    .byte KEY_RETURN
    .text " R    - DISPLAY CPU REGISTERS"
    .byte KEY_RETURN, $80