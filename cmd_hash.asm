#import "utils.asm"
#import "parser_functions.asm"

// -----------------------------------------------------------------------------
// Change default device number
// KEY_A device 10
// KEY_B device 11
// KEY_C CSDB.dk
// KEY_F Ultimate 64 Flash
// KEY_H Ultimate 64 Home
// KEY_S SD2IEC
// KEY_T Ultimate 64 Temp
// KEY_@ Hondani Cloud

// -----------------------------------------------------------------------------
// Purpose:
//   Change device for subsequent default operations.
// Usage:
//   #<device_number>
//     - '#' followed by single character device number sets the default device for file operations.
//   #
//     - '#' without a number display current default device.
// Notes:
//   - Device number is a single character (8,9,A,B,C,F,H,S,T,@).

cmd_hash:
	ldy parser_input_cursor         // Y = input_cursor position
    dey                             // previous char
    jsr next_char_exec              // reuse next_char logic
    cmp #KEY_8
    bne !+
    lda #8
    sta FA  // set default device to 8
    jmp !finish+
!:
    cmp #KEY_9
    bne !+
    lda #9
    sta FA  // set default device to 9
    jmp !finish+
!:
    cmp #KEY_A
    bne !+
    lda #10
    sta FA  // set default device to 10
    jmp !finish+
!:
    cmp #KEY_B
    bne !+
    lda #11
    sta FA  // set default device to 11
    jmp !finish+
!:
    cmp #KEY_HASH
    beq !print_device+
    // other devices, just store value
    sta FA
    jmp !finish+

!print_device:
    lda FA
    cmp #$08
    bne !+
    lda #KEY_8
    jmp !print_char+
!:
    cmp #$09
    bne !+
    lda #KEY_9
    jmp !print_char+
!:
    cmp #$0A
    bne !+
    lda #KEY_A
    jmp !print_char+
!:
    cmp #$0B
    bne !print_char+
    lda #KEY_B
!print_char:
    jsr CHROUT

!finish:
    ParsingInputsDone() // finish parsing input line

    CommandDone()  // jump to parser completion handler in parser.asm