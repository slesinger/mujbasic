#import "constants.asm"
#import "cmd_empty.asm"
#import "cmd_hash.asm"
#import "cmd_cd.asm"
#import "cmd_g.asm"
#import "cmd_help.asm"
#import "cmd_l.asm"
#import "cmd_lsll.asm"
#import "cmd_m.asm"
#import "cmd_r.asm"
#import "cmd_run.asm"
#import "cmd_unknown.asm"

// Token Table for parser generalisation
// Parser iterates over "current letter" which is a structure of 3 bytes:
// 1. expected key code
// 2. low byte address of next letter structure (or command execution address)
// 3. high byte address of next letter structure (or command execution address)
// This table is ordered by visiting token tree depth-first. Token tree rows are orderd alphabetically.
// KEY_NULL must always go to as a first item of table because if white space or end of string is reached, parser jumps to KEY_NULL entry to get command address.
// If table for current letter does not resolve to full command then KEY_NULL must be there also to resolve to end_of_command and defaults to read the first entry.
// If command can have arguments, KEY_SPACE entry must be there to resolve to command execution address.
// Each table must end by PARSER_END_OF_TABLE marker.
.byte $88, $88, $88, $88
tbl:
.byte KEY_NULL, <tbl_null, >tbl_null  // empty line
.byte KEY_HASH, <tbl_hash, >tbl_hash
.byte KEY_C, <tbl_c, >tbl_c
.byte KEY_G, <tbl_g, >tbl_g
.byte KEY_H, <tbl_h, >tbl_h
.byte KEY_L, <tbl_l, >tbl_l
.byte KEY_M, <tbl_m, >tbl_m
.byte KEY_R, <tbl_r, >tbl_r
.byte PARSER_END_OF_TABLE
.byte PARSER_END_OF_TABLE
.byte PARSER_END_OF_TABLE

tbl_null:
.byte KEY_NULL, <cmd_empty, >cmd_empty  // empty line


// Top level #
tbl_hash:
.byte KEY_NULL, <cmd_hash, >cmd_hash
.byte KEY_8, <tbl_hash_device, >tbl_hash_device
.byte KEY_9, <tbl_hash_device, >tbl_hash_device
.byte KEY_A, <tbl_hash_device, >tbl_hash_device  // device 10
.byte KEY_B, <tbl_hash_device, >tbl_hash_device  // device 11
.byte KEY_C, <tbl_hash_device, >tbl_hash_device  // CSDB.dk
.byte KEY_F, <tbl_hash_device, >tbl_hash_device  // Ultimate 64 Flash
.byte KEY_H, <tbl_hash_device, >tbl_hash_device  // Ultimate 64 Home
.byte KEY_S, <tbl_hash_device, >tbl_hash_device  // SD2IEC
.byte KEY_T, <tbl_hash_device, >tbl_hash_device  // Ultimate 64 Temp
.byte KEY_AMPERSAND, <tbl_hash_device, >tbl_hash_device  // Hondani Cloud
.byte PARSER_END_OF_TABLE

tbl_hash_device:
.byte KEY_NULL, <cmd_hash, >cmd_hash
.byte PARSER_END_OF_TABLE


// Top level C
tbl_c:
.byte KEY_NULL, <cmd_unknown, >cmd_unknown  // c without arguments
.byte KEY_D, <tbl_cd, >tbl_cd
.byte PARSER_END_OF_TABLE

tbl_cd:
.byte KEY_NULL, <cmd_cd, >cmd_cd
.byte PARSER_END_OF_TABLE


// Top level G
tbl_g:
.byte KEY_NULL, <cmd_g, >cmd_g  // g without arguments  // TODO g has one mandatory argument - address
.byte PARSER_END_OF_TABLE


// Top level H
tbl_h:
.byte KEY_NULL, <cmd_unknown, >cmd_unknown
.byte KEY_E, <tbl_he, >tbl_he
.byte PARSER_END_OF_TABLE

tbl_he:
.byte KEY_NULL, <cmd_unknown, >cmd_unknown
.byte KEY_L, <tbl_hel, >tbl_hel
.byte PARSER_END_OF_TABLE

tbl_hel:
.byte KEY_NULL, <cmd_unknown, >cmd_unknown
.byte KEY_P, <tbl_help, >tbl_help
.byte PARSER_END_OF_TABLE

tbl_help:
.byte KEY_NULL, <cmd_help, >cmd_help  // no args
.byte PARSER_END_OF_TABLE


// Top level L
tbl_l:
// .byte KEY_NULL, <cmd_l, >cmd_l
.byte KEY_SPACE, <cmd_l, >cmd_l  // l with arguments
.byte KEY_L, <tbl_ll, >tbl_ll
.byte KEY_S, <tbl_ls, >tbl_ls
.byte PARSER_END_OF_TABLE

tbl_ll:
.byte KEY_NULL, <cmd_ll, >cmd_ll   // ll without arguments
.byte KEY_SPACE, <cmd_ll, >cmd_ll  // ll with arguments
.byte PARSER_END_OF_TABLE

tbl_ls:
.byte KEY_NULL, <cmd_ls, >cmd_ls   // ls without arguments  // must be fist position to read command address after carry flag identifies the end of command
.byte KEY_SPACE, <cmd_ls, >cmd_ls  // ls with arguments
.byte PARSER_END_OF_TABLE


// Top level M
tbl_m:
.byte KEY_NULL, <cmd_m, >cmd_m   // m without arguments
.byte KEY_SPACE, <cmd_m, >cmd_m  // m with arguments
.byte PARSER_END_OF_TABLE


// Top level R
tbl_r:
.byte KEY_NULL, <cmd_r, >cmd_r  // r without arguments
.byte KEY_U, <tbl_ru, >tbl_ru
.byte KEY_SHIFT_U, <tbl_rU, >tbl_rU
.byte PARSER_END_OF_TABLE

tbl_ru:
.byte KEY_NULL, <cmd_unknown, >cmd_unknown
.byte KEY_N, <tbl_run, >tbl_run
.byte PARSER_END_OF_TABLE

tbl_rU:
.byte KEY_NULL, <cmd_run, >cmd_run  // no args
.byte PARSER_END_OF_TABLE

tbl_run:
.byte KEY_NULL, <cmd_run, >cmd_run  // no args
.byte PARSER_END_OF_TABLE
