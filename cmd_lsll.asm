#import "floppy.asm"

// -----------------------------------------------------------------------------
// List Directory Command
// -----------------------------------------------------------------------------
// Purpose:
//   Displays the contents of the current or specified directory.
//   LS is using condesnsed listing format.
//   LL is using long listing standard C64 format.
// Usage:
//   LS
//   LS 8:/PATH/  ; list directory of PATH on drive 8
//   LL medlik.prg  ; long listing of file medlik.prg
// Notes:
//   - Listing any drives or attached file systems.
// <ls_command> ::= "ls" [ <ws> ( <file_or_path> ) ]  ; command code 12
// <ll_command> ::= "ll" [ <ws> ( <file_or_path> ) ]  ; command code 25

cmd_ll:
    ParsingInputsDone() // finish parsing input line

    // filename = $
    lda #KEY_DOLLAR
    sta directory_listing_addr  // will be overwritten but who cares
    lda #$01  // length 1
    sta FNLEN
    lda #$00
    sta SAVX        // Clear SAVX to indicate no load address
    sta ZP_INDIRECT_ADDR  // file name shares the same memory location as loaded directory entries but it's ok
    lda #>directory_listing_addr  // working memory directory_listing_addr
    sta SAVY        // Clear SAVY to indicate no load address
    sta ZP_INDIRECT_ADDR + 1
    jsr load_file

    // print out directory here
print_dir_loop:
line_loop:
    ldy #$00
    // read type (2 byte) ??
    lda (ZP_INDIRECT_ADDR),y  // expect $01
    iny
    lda (ZP_INDIRECT_ADDR),y  // expect $01
    iny
    // read file size (2 bytes) ??
    lda (ZP_INDIRECT_ADDR),y
    iny
    sta TMP2        // low byte of file size
    lda (ZP_INDIRECT_ADDR),y
    iny
    sta TMP2+1      // high byte of file size
    // print the length  TMP2 = low byte, TMP2+1 = high byte)
    sty SAVY  // save y register
    jsr CVTDEC_tmp2         // convert TMP2/TMP2+1 to BCD in U0AA0
    lda #0             // clear digit counter
    ldx #6             // max 6 digits
    ldy #3             // 3 bits per digit (decimal)
    jsr nmprnt         // print decimal value    // padding bytes (1-3 spaces), filename, extension, simply print everyting until $00, $01
    ldy SAVY  // restore y register
inner_chars:
    lda (ZP_INDIRECT_ADDR),y
    iny
    cmp #$00
    beq line_done
    jsr CHROUT
    jmp inner_chars
line_done:
    // print new line and expect $00
    lda #KEY_RETURN
    jsr CHROUT
    lda (ZP_INDIRECT_ADDR),y
    // iny
    cmp #$00
    beq end_of_dir
    // next line, add y to pointer
    tya
    clc
    adc ZP_INDIRECT_ADDR
    sta ZP_INDIRECT_ADDR
    lda ZP_INDIRECT_ADDR + 1
    adc #$00
    sta ZP_INDIRECT_ADDR + 1
    jmp line_loop
end_of_dir:
    CommandDone()  // jump to parser completion handler in parser.asm

cmd_ls:
    CommandDone()  // jump to parser completion handler in parser.asm
