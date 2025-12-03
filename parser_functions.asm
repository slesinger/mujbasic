#importonce
#import "constants.asm"

// Returns next char from input string, or sets Carry flag if at end
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
    bcs skip_whitespace_done       // If Carry set (end of input), done
    cmp #PARSER_WHITESPACE         // Compare A with whitespace char
    bne skip_whitespace_done
    inc parser_input_cursor        // input_cursor += 1
    jmp skip_whitespace_loop
skip_whitespace_done:
    rts


