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
    // TODO
    lda #$34
    // execute actual job
    rts  // back to parser cmd_exec_addr

cmd_ls:
    nop
    nop
    nop
    jmp parse_done  // jump to parser completion handler in parser.asm
