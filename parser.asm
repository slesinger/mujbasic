#import "constants.asm"
#import "parser_functions.asm"


// Main parser routine
// Reads input string from PARSER_INPUT_PTR, parses it according to token tables and jumps ???

parse_input:
    // input_cursor = -1
    lda #$ff
    sta parser_input_cursor

    // skip_whitespace()
    jsr skip_whitespace
    // TODO consider bcs > rts if end of string reached here (only whitespace line or $00)
    // Read inital command character
    jsr next_char        // cursor moved, A holds next char, Y destroyed
    // Initialize command parsing table search
    // set initial indirect pointer to root token table
    ldy #<tbl
    sty ZP_INDIRECT_ADDR
    ldy #>tbl
    sty ZP_INDIRECT_ADDR+1
    ldy #$00 - 3  // set to first record minus 3 to simplify loop

    // process current character against token table
next_token_char_position:
    // move to next key in table
    iny
    iny
    iny

    // compare A with table entry
cmp_addr:
    cmp (ZP_INDIRECT_ADDR),y  // compare with expected key code (can be white space that indicates end of command)
    beq match_found
    // not matched, check for end of table
    pha
    lda (ZP_INDIRECT_ADDR),y
    cmp #PARSER_END_OF_TABLE
    bne !+  // end of table reached, command unknown
    pla
    jsr cmd_unknown
    jmp parse_done
!:  pla
    jmp next_token_char_position
    // match found, load address of next table or command
match_found:
    iny  // point to low byte of next table
    lda (ZP_INDIRECT_ADDR),y
    tax // store low byte of next table address in X because storing it directly sta ZP_INDIRECT_ADDR would destroy the next indirect reading
    iny  // point to high byte of next table
    lda (ZP_INDIRECT_ADDR),y
    stx ZP_INDIRECT_ADDR    // low
    sta ZP_INDIRECT_ADDR+1  // high
    // read next char into A (Y destroyed)
    jsr next_char
    bcs end_of_command  // if end of string -> end of command, read address of first item in the current table to execute command
    // if next char is white space, end of command also
    cmp #PARSER_WHITESPACE
    beq end_of_command
    // continue parsing with next char
    ldy #$00
    jmp cmp_addr  // jump to new table

end_of_command:
    // no more chars, execute command at current address
    // A contains last read char (white space or $00)
    // load address of command to execute
    ldy #$01
    lda (ZP_INDIRECT_ADDR),y  // low byte of command address
    tax  // do not break next indirect reading
    iny
    lda (ZP_INDIRECT_ADDR),y
    sta ZP_INDIRECT_ADDR_2+1
    stx ZP_INDIRECT_ADDR_2
    // jump to command execution
cmd_exec_addr:
    jmp (ZP_INDIRECT_ADDR_2)  // rewritable address

// parse done handler
parse_done:
    rts

#import "parser_tables.asm"
