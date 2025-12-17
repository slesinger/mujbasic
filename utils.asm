#importonce 
#import "constants.asm"


// Executes code at address
// Note: does not return! Use jmp instead of jsr to call this routine.
// Input: SAVX = low byte of address, SAVY = high byte of address
run_address:
    lda SAVX            // load A from saved low byte
    sta PCL             // set PC low byte
    lda SAVY            // load A from saved high byte
    sta PCH             // set PC high byte

    ldx SP              // load stack pointer from memory
    txs                 // save in SP register
    // jsr COPY1P          // copy provided address to PC
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


petscii2screen:
/*
# Generate scrcode_from_petscii mapping
scrcode_from_petscii = []
for petscii in range(0, 256):
    # Special handling for $FF (pi symbol)
    if petscii == 0xff:
        petscii = 0xde

    # Conversion logic
    if petscii < 0x20:
        scrcode = petscii + 0x80  # Inverted control chars
    elif petscii < 0x40:
        scrcode = petscii
    elif petscii < 0x60:
        scrcode = petscii - 0x40
    elif petscii < 0x80:
        scrcode = petscii - 0x20
    elif petscii < 0xa0:
        scrcode = petscii + 0x40  # Inverted
    elif petscii < 0xc0:
        scrcode = petscii - 0x40
    else:
        scrcode = petscii - 0x80

    scrcode_from_petscii.append(scrcode)
*/
    // Special case: petscii $FF corresponds to screen code $DE (pi)
    cmp #$FF
    beq !to_de+
    // petscii 00..1F -> scrcode = petscii + 0x80
    cmp #$20
    bcc !add80+
    // petscii 20..3F -> scrcode = petscii
    cmp #$40
    bcc !same+
    // petscii 40..5F -> scrcode = petscii - 0x40
    cmp #$60
    bcc !sub40+
    // petscii 60..7F -> scrcode = petscii - 0x20
    cmp #$80
    bcc !sub20+
    // petscii 80..9F -> scrcode = petscii + 0x40
    cmp #$A0
    bcc !add40+
    // petscii A0..BF -> scrcode = petscii - 0x40
    cmp #$C0
    bcc !sub40+
    // petscii C0..FF -> scrcode = petscii - 0x80
    jmp !sub80+
    rts

// Convert screen code in A to petscii
// Input: A = screen code
// Output: A = petscii code
// Killed registers: None
screen2petscii:
/*
# Generate petscii_from_scrcode mapping
petscii_from_scrcode = []
for scrcode in range(0, 256):
    # Reverse conversion logic
    if scrcode < 0x20:  // @A PQ
        petscii = scrcode + 0x40
    elif scrcode < 0x40: // <SPC>! 01
        petscii = scrcode
    elif scrcode < 0x60:  // -<tree> LO
        petscii = scrcode + 0x20
    elif scrcode < 0x80:  // <SPC>| <pig>
        petscii = scrcode + 0x40

    elif scrcode < 0xa0:
        petscii = scrcode - 0x40? # Inverted
    elif scrcode < 0xc0:
        petscii = scrcode + 0x40?
    else:
        petscii = scrcode + 0x80?
    petscii_from_scrcode.append(petscii)
*/
    // Special case: screen code $DE corresponds to PETSCII $FF (pi)
    cmp #$DE
    beq !to_ff+
    and #$7F  // clear reversed bit
    // scr 00..1F -> petscii = scr + 0x40
    cmp #$20
    bcc !add40+
    // scr 20..3F -> petscii = scr
    cmp #$40
    bcc !same+
    // scr 40..5F -> petscii = scr + 0x20
    cmp #$60
    bcc !add20+
    // scr 60..7F -> petscii = scr + 0x40
    cmp #$80
    bcc !add40+
    // scr 80..9F -> petscii = scr - 0x80
    jmp !same+

!add20:
    clc
    adc #$20
    rts
!add40:
    clc
    adc #$40
    rts
!add80:
    clc
    adc #$80
    rts
!same:
    rts
!to_ff:
    lda #$FF
    rts
!to_de:
    lda #$DE
    rts
!sub20:
    sec
    sbc #$20
    rts
!sub40:
    sec
    sbc #$40
    rts
!sub80:
    sec
    sbc #$80
    rts

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
// Input: TMP2 = low byte, TMP2+1 = high byte of address to print
// Kills: A, X
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
    lda #KEY_SPACE      // output space
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


// convert binary to BCD
// Input: TMP0 = low byte, TMP0+1 = high byte of binary value
// Input: alternatively call CVTDEC_tmp2 for TMP2 = low byte, TMP2+1 = high byte of binary value

// CVTDEC:  jsr COPY12          // copy value from TMP0 to TMP2
CVTDEC_tmp2:
         lda #0
         ldx #2              // clear 3 bytes in work buffer
DECML1:  sta U0AA0,x
         dex
         bpl DECML1
         ldy #16             // 16 bits in input
         php                 // save status register
         sei                 // make sure no interrupts occur with BCD enabled
         sed
DECML2:  asl TMP2            // rotate bytes out of input low byte
         rol TMP2+1          // .. into high byte and carry bit
         ldx #2              // process 3 bytes
DECDBL:  lda U0AA0,x         // load current value of byte
         adc U0AA0,x         // add it to itself plus the carry bit
         sta U0AA0,x         // store it back in the same location
         dex                 // decrement byte counter
         bpl DECDBL          // loop until all bytes processed
         dey                 // decrement bit counter
         bne DECML2          // loop until all bits processed
         plp                 // restore processor status
         rts


// print number in specified base without leading zeros
nmprnt:  sta DIGCNT          // number of digits in accumulator
         sty NUMBIT          // bits per digit passed in y register
digout:  ldy NUMBIT          // get bits to process
         lda #0              // clear accumulator
rolbit:  asl U0AA0+2         // shift bits out of low byte
         rol U0AA0+1         // ... into high byte
         rol U0AA0           // ... into overflow byte
         rol                 // ... into accumulator
         dey                 // decrement bit counter
         bpl rolbit          // loop until all bits processed
         tay                 // check whether accumulator is 0
         bne nzero           // if not, print it
         cpx #1              // have we output the max number of digits?
         beq nzero           // if not, print it
         ldy DIGCNT          // how many digits have we output?
         beq zersup          // skip output if digit is 0
nzero:   inc DIGCNT          // increment digit counter
         ora #$30            // add numeric value to ascii '0' to get ascii char
         jsr CHROUT          // output character
zersup:  dex                 // decrement number of leading zeros
         bne digout          // next digit
         rts


// subtract TMP2 from TMP0
SUB12:
    sec
    lda TMP0            // subtract low byte
    sbc TMP2
    sta TMP0
    lda TMP0+1
    sbc TMP2+1          // subtract high byte
    sta TMP0+1
    rts

// subtract from TMP0
SUBA1:
    lda #1              // shortcut to decrement by 1
SUBA2:
    sta SAVX            // subtrahend in accumulator
    sec
    lda TMP0            // minuend in low byte
    sbc SAVX
    sta TMP0
    lda TMP0+1          // borrow from high byte
    sbc #0
    sta TMP0+1
    rts

// add to TMP2
ADDA2:
    lda #1              // shortcut to increment by 1
BUMPAD2:
    clc
    adc TMP2            // add value in accumulator to low byte
    sta TMP2
    bcc BUMPEX
    inc TMP2+1          // carry to high byte
BUMPEX:
    rts 

// display 8 bytes of memory
DISPMEM:
    jsr CRLF            // new line
    lda #KEY_GREATER_THAN  // prefix > so memory can be edited in place
    jsr CHROUT
    jsr SHOWAD          // show address of first byte on line
    ldy #0
    beq DMEMGO          // SHOWAD already printed a space after the address
DMEMLP:
    jsr SPACE           // print space between bytes
DMEMGO:
    lda (TMP2),Y        // load byte from start address + Y
    jsr WRTWO           // output hex digits for byte
    iny                 // next byte
    cpy #8              // have we output 8 bytes yet?
    bcc DMEMLP          // if not, output next byte
    ldy #MSG5-MSGBAS    // if so, output : and turn on reverse video
    jsr SNDMSG          //   before displaying ascii representation
    ldy #0              // back to first byte in line
DCHAR:
    lda (TMP2),Y        // load byte at start address + Y
    tax                 // stash in X
    and #$BF            // clear 6th bit
    cmp #KEY_QUOTE      // is it a quote (")?
    beq DDOT            // if so, print . instead
    txa                 // if not, restore character
    and #$7F            // clear top bit
    cmp #KEY_SPACE      // is it a printable character (>= $20)?
    txa                 // restore character
    bcs DCHROK          // if printable, output character
DDOT:
    lda #KEY_DOT        // if not, output '.' instaed
DCHROK:
    jsr CHROUT
    iny                 // next byte
    cpy #8              // have we output 8 bytes yet?
    bcc DCHAR           // if not, output next byte
    rts 

// handle error
ERROR:
    ldy #MSG3-MSGBAS    // display "?" to indicate error and go to new line
    jsr SNDMSG
    CommandDone()      // back to main loop

// message table// last character has high bit set
MSGBAS:
MSG2:
    .text "   PC  SR AC XR YR SP   V0.1"  // header for registers
    .byte KEY_RETURN, $80    // end of message marker
MSG3:
    .byte $1D,$3F+$80       // syntax error: move right, display "?"
MSG5:
    .byte KEY_SPACE, KEY_SPACE, $12+$80       // ":" then RVS ON for memory ASCII dump
MSG_UNKNOWN_COMMAND:
    .text "COMMAND NOT FOUND"
    .byte KEY_RETURN, $80
MSG_HELP:
    .byte KEY_RETURN
    .text "AVAILABLE COMMANDS:"
    .byte KEY_RETURN
    .text " HELP - DISPLAY THIS HELP MESSAGE"
    .byte KEY_RETURN
    .text " R    - DISPLAY CPU REGISTERS"
    .byte KEY_RETURN, $80