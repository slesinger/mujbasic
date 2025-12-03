#import "constants.asm"
#import "parser_functions.asm"


*= $0801 "Basic Upstart"
    BasicUpstart(start)    // 10 sys$0810

* = PARSER_INPUT_PTR
.text "HELP"; .byte 0

* = $1000

// this is a test code that will read from PARSER_INPUT_PTR and output structure to $2000
start:
    // input_cursor = -1
    lda #$ff
    sta parser_input_cursor
    jmp parse_input

// Temporary parse done handler
parse_done:
    sta $0500
    inc $d020
    jmp parse_done




// Main parser routine
// Reads input string from PARSER_INPUT_PTR, parses it according to token tables and jumps ???

parse_input:
    // skip_whitespace()
    jsr skip_whitespace
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
    sta ZP_INDIRECT_ADDR+1
    stx ZP_INDIRECT_ADDR
    // read next char into A (Y destroyed)
    jsr next_char
    bcs end_of_command  // if end of string -> end of command, read address to execute command
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
    sta cmd_exec_addr+2
    stx cmd_exec_addr+1
    // jump to command execution
cmd_exec_addr:
    jsr $ffff  // rewritable address
    jmp parse_done


#import "parser_tables.asm"
