#importonce
#import "constants.asm"

// Returns next char from input string, or sets Carry flag if at end. Move parser_input_cursor to the position of the returned char.
// Input_str is $00 terminated string
// Output: A = next char + Carry flag cleared, or Carry flag set if end of string
// Retains: X
/*
def next_char():
    global input_cursor
    input_cursor += 1
    if input_cursor >= PARSER_MAX_INPUT_LEN:  # 89 is max length
        return None
    if input_cursor < len(input_str):  # indicated by $00 terminator
        return input_str[input_cursor]
    return None
*/
next_char:
	inc parser_input_cursor         // input_cursor += 1
	ldy parser_input_cursor         // Y = input_cursor position
next_char_exec:
    cpy #PARSER_MAX_INPUT_LEN       // if input_cursor >= PARSER_MAX_INPUT_LEN
    bcs next_char_return_none       //   return None
	lda PARSER_INPUT_PTR,y          // A = input_str[y]  A holds next character in string
    and #$7f                        // mask high bit just in case it is reversed, it is accepted as normal character
    beq next_char_return_none       // If A == $00, null terminated string, return None (set Carry flag)
    clc                             // Clear Carry flag to indicate valid character
    rts
next_char_return_none:
    sec                             // Set Carry flag to indicate end of string
    rts


// Returns next char from input string without moving the pointer, or sets Carry flag if at end
// Input_str is $00 terminated string
// Output: A = next char + Carry flag cleared, or Carry flag set if end of string
/*
def peek_char():
    if input_cursor + 1 < len(input_str):
        return input_str[input_cursor + 1]
    return None
*/
peek_char:
	ldy parser_input_cursor         // Y = input_cursor position
    iny                             // like input_cursor + 1 but not changing stored value
    jmp next_char_exec              // reuse next_char logic


// See if next char is whitespace or end of stringwithout moving the pointer. Useful to see if we are at last char of command.
// Input: None
// Output: Carry flag set if end of string or whitespace, Carry clear otherwise
peek_cmd_end:
	ldy parser_input_cursor         // Y = input_cursor position
    iny                             // like input_cursor + 1 but not changing stored value
    cpy #PARSER_MAX_INPUT_LEN       // if input_cursor >= PARSER_MAX_INPUT_LEN
    bcs next_char_return_none       //   return None
	lda PARSER_INPUT_PTR,y          // A = input_str[y]  A holds next character in string
    and #$7f
    cmp #PARSER_WHITESPACE         // Compare A with whitespace char
    beq next_char_return_none       // If A == $00, return None (set Carry flag)
    clc                             // Clear Carry flag to indicate valid character
    rts


// Advances input cursor while next char is whitespace
// Input: None
// Output: Carry flag set if end of string reached
/*
def skip_whitespace():
    global input_cursor
    while (
        input_cursor + 1 < len(input_str)
        and input_str[input_cursor + 1] == " "
    ):
        input_cursor += 1
*/
skip_whitespace:
skip_whitespace_loop:
    jsr peek_char                  // A = next char, or Carry set if end
    bcs skip_whitespace_eos       // If Carry set (end of input), done
    cmp #PARSER_WHITESPACE         // Compare A with whitespace char
    bne skip_whitespace_eows
    inc parser_input_cursor        // input_cursor += 1
    jmp skip_whitespace_loop
skip_whitespace_eows:
    clc
skip_whitespace_eos:
    rts


// Output: filename pointer at ZP_INDIRECT_ADDR_2
// Output: filename length in FNLEN
// Error: Carry flag if there is no filename
parse_file_or_path:
    jsr skip_whitespace
    bcc parse_file_ws_skipped_ok
    sec  // report error as end of string reached without filename argument
    rts
parse_file_ws_skipped_ok:
    jsr next_char
    // return starting pointer of filename and add to it current cursor position
    clc
    lda #<PARSER_INPUT_PTR
    adc parser_input_cursor
    sta ZP_INDIRECT_ADDR
    lda #>PARSER_INPUT_PTR
    adc #$00
    sta ZP_INDIRECT_ADDR + 1

    // calculate length of filename
    lda parser_input_cursor
    sta SAVX                       // initial cursor position
parse_file_loop:
    jsr next_char                  // A = next char, or Carry set if end
    bcs parse_filename_done            // If Carry set (end of input), done
    cmp #PARSER_WHITESPACE         // Compare A with whitespace char
    bne parse_file_loop
parse_filename_done:
    // length = current cursor - initial cursor
    lda parser_input_cursor
    sec
    sbc SAVX
    sta FNLEN                      // store filename length
    clc  // TODO
    rts


// Parse hexadecimal address from input string
// Input: None
// Output: SAVX = low byte of address, SAVY = high byte of address
// Output: A = number of digits read
// Error: Carry flag set on error
parse_address:
    jsr skip_whitespace
    jsr RDVAL
    rts

// read hexa address from input string
// Input: TBD
// Output: SAVX = low byte, SAVY = high byte of address
// Output: A = number of digits read
// Error: Carry flag set on error
// read a value in the specified base
RDVAL:
    lda #0              // clear temp
    sta SAVX
    sta SAVY
    sta DIGCNT          // clear digit counter
    txa                 // save X and Y
    pha
    tya
    pha
RDVMOR:
    jsr next_char       // get next character from input buffer
    bcs RDNILK          // null at end of buffer
    cmp #KEY_SPACE      // skip spaces
    beq RDVMOR

    cmp #KEY_PERCENT    // binary
    bne !+
    ldy #$02            // base 2
    lda #$01            // 1 bit per digit
    sta NUMBIT
    jmp NUDIG
!:  cmp #KEY_AMPERSAND  // octal
    bne !+
    ldy #$08            // base 8
    lda #$03            // 3 bits per digit
    sta NUMBIT
    jmp NUDIG
!:  cmp #KEY_PLUS       // decimal  // TODO does not work
    bne !+
    ldy #$0A            // base 10
    lda #$03            // 4 bits per digit
    sta NUMBIT
    jmp NUDIG
!:  cmp #KEY_DOLLAR      // hexadecimal
    beq !+
    dec parser_input_cursor  // unconsume char
!:  // hexadecimal as default
    ldy #$10            // base 16
    lda #$04            // 4 bits per digit
    sta NUMBIT
NUDIG:
    sty _TMP
    jsr next_char       // get next char in A, kills y
    ldy _TMP
RDNILK:
    bcs RDNIL           // end of number if no more characters
    sec
    sbc #$30            // subtract ascii value of 0 to get numeric value
    bcc RDNIL           // end of number if character was less than 0
    cmp #KEY_CTRL_J     // compare with ascii 0A
    bcc DIGMOR          // not a hex digit if less than A
    sbc #$07            // 7 chars between ascii 9 and A, so subtract 7
    cmp #$10            // end of number if char is greater than F
    bcs RDNIL
DIGMOR:
    sta INDIG           // store the digit
    cpy INDIG           // compare base with the digit
    bcc RDERR           // error if the digit >= the base
    beq RDERR
    inc DIGCNT          // increment the number of digits
    cpy #10
    bne NODECM          // skip the next part if not using base 10
    ldx #1
DECLP1:
    lda SAVX,X          // stash the previous 16-bit value for later use
    sta STASH,X
    dex
    bpl DECLP1
NODECM:
    ldx NUMBIT          // number of bits to shift
TIMES2:
    asl SAVX            // shift 16-bit value by specified number of bits
    rol SAVY
    bcs RDERR           // error if we overflowed 16 bits
    dex
    bne TIMES2          // shift remaining bits
    cpy #10
    bne NODEC2          // skip the next part if not using base 10
    asl STASH           // shift the previous 16-bit value one bit left
    rol STASH+1
    bcs RDERR           // error if we overflowed 16 bits
    lda STASH           // add shifted previous value to current value
    adc SAVX
    sta SAVX
    lda STASH+1
    adc SAVY
    sta SAVY
    bcs RDERR           // error if we overflowed 16 bits
NODEC2:
    clc 
    lda INDIG           // load current digit
    adc SAVX            // add current digit to low byte
    sta SAVX            // and store result back in low byte
    txa                 // A=0
    adc SAVY          // add carry to high byte
    sta SAVY          // and store result back in high byte
    bcc NUDIG           // get next digit if we didn't overflow
RDERR:
    sec                 // set carry to indicate error
    .byte $24           // BIT ZP opcode consumes next byte (CLC)
RDNIL:
    clc                 // clear carry to indicate success
    sty NUMBIT          // save base of number
    pla                 // restore X and Y
    tay
    pla
    tax
    lda DIGCNT          // return number of digits in A
    rts
