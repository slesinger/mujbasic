#importonce
// ============================================================================
// constants.asm - Shared Constants for HONDANI Shell
// ============================================================================
// This file contains all shared constants for the project.
// ============================================================================

// Runtime variables Zero page locations
.const SAVX = $02                  // 1 byte temp storage, often to save X register
.const ZP_INDIRECT_ADDR = $b2      // +$b3 Repurposable Zero page indirect address pointer 1
.const FNLEN = $B7                 // length of current filename
.const SADD = $B9                  // current secondary address (official name SA) like, load "*",8,1 <- put 1 into SADD
.const FA = $BA                    // current device number
.const FNADR = $BB                 // $00BB-$00BC pointer to current filename
.const ZP_INDIRECT_ADDR_2 = $c1    // +$c2 Repurposable Zero page indirect address pointer 2
.const TMP0 = $c1                  // +$c2 Repurposable Zero page indirect address pointer 2 used in SMON
.const TMP2 = $c3                  // usually holds start address
.const REU_SIZE_BANKS = $FB        // Number of 64KB banks detected

.const InputBuffer  = $0200        // Input buffer in RAM (safe area page 3, 256 bytes)
// 8 bytes $0334-$033B global vars Eight free bytes for user vectors or other data.
.const PCH = $0334                 // program counter high byte
.const PCL = $0335                 // program counter low byte
.const SR = $0336
.const ACC = $0337
.const XR = $0338
.const YR = $0339
.const SP = $033A
.const parser_input_cursor = $033B // Current position in parser input string, only used when parsing

// 192 bytes cassete buffer $033C-$03FB
.const InputLength  = $033C        // Current length of input (in RAM - safe area)
.const CursorPos    = $033D        // Current cursor position within user input line (in RAM - safe area)

// Read-only system constants
.const PNT = $d1                   // Read-only $00D1-$00D2	PNT	Pointer to the Address of the Current Screen Line
.const PNTR = $d3                  // Read-only $00D3	PNTR	Cursor Column on Current Line 0-79




// KERNAL routines
.const CLRSCR  = $E544             // KERNAL clear screen routine
.const SETMSG  = $FF90             // set kernel message control flag
.const SECOND  = $FF93             // set secondary address after LISTEN
.const TKSA    = $FF96             // send secondary address after TALK
.const LISTEN  = $FFB1             // command serial bus device to LISTEN
.const TALK    = $FFB4             // command serial bus device to TALK
.const SETLFS  = $FFBA             // set logical file parameters
.const SETNAM  = $FFBD             // set filename
.const ACPTR   = $FFA5             // input byte from serial bus
.const CIOUT   = $FFA8             // output byte to serial bus
.const UNTLK   = $FFAB             // command serial bus device to UNTALK
.const UNLSN   = $FFAE             // command serial bus device to UNLISTEN
.const CHKIN   = $FFC6             // define input channel
.const CLRCHN  = $FFCC             // restore default devices
.const INPUT   = $FFCF             // input a character (official name CHRIN)
.const CHROUT  = $FFD2             // output a character
.const LOAD    = $FFD5             // load from device
.const SAVE    = $FFD8             // save to device
.const STOP    = $FFE1             // check the STOP key
.const GETIN   = $FFE4             // get a character

// Input key codes
.const KEY_NULL = $00
.const KEY_RETURN = $0D
.const KEY_DELETE = $14
.const KEY_CURSOR_RIGHT = $1D
.const KEY_SPACE = $20
.const KEY_DOLLAR = $24
.const KEY_MINUS = $2d
.const KEY_EQUAL = $3d
.const KEY_A = $41
.const KEY_B = $42
.const KEY_C = $43
.const KEY_D = $44
.const KEY_E = $45
.const KEY_F = $46
.const KEY_G = $47
.const KEY_H = $48
.const KEY_I = $49
.const KEY_J = $4a
.const KEY_K = $4b
.const KEY_L = $4c
.const KEY_M = $4d
.const KEY_N = $4e
.const KEY_O = $4f
.const KEY_P = $50
.const KEY_Q = $51
.const KEY_R = $52
.const KEY_S = $53
.const KEY_T = $54
.const KEY_U = $55
.const KEY_V = $56
.const KEY_W = $57
.const KEY_X = $58
.const KEY_Y = $59
.const KEY_Z = $5a
.const KEY_CURSOR_LEFT  = $9D

// Screen and color RAM
.const SCREEN_RAM   = $0400     // Screen memory start
.const COLOR_RAM    = $D800     // Color memory start
.const BORDER_COLOR = $D020     // Border color register
.const BG_COLOR     = $D021     // Background color register

// Colors
.const LIGHT_BLUE   = $0E
.const BLUE         = $06
.const WHITE        = $01

// REU (RAM Expansion Unit) registers
.const REU_STATUS      = $DF00  // Status register
.const REU_COMMAND     = $DF01  // Command register
.const REU_C64_ADDR_LO = $DF02  // C64 base address (low)
.const REU_C64_ADDR_HI = $DF03  // C64 base address (high)
.const REU_REU_ADDR_LO = $DF04  // REU base address (low)
.const REU_REU_ADDR_HI = $DF05  // REU base address (high)
.const REU_REU_BANK    = $DF06  // REU bank
.const REU_LENGTH_LO   = $DF07  // Transfer length (low)
.const REU_LENGTH_HI   = $DF08  // Transfer length (high)

// MujBASIC working area
.const MUJBASIC_CURRENT_DRIVE = $0313 // Current drive number used as default for listing directory and file operations

// Parser
.const PARSER_INPUT_PTR = InputBuffer  // temporary
.const PARSER_MAX_INPUT_LEN = 79 // Maximum length of user input
.const PARSER_WHITESPACE = $20 // ASCII space character used as whitespace in parser
.const PARSER_END_OF_TABLE = $FF // Special marker indicating end of parser token table