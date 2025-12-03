#importonce
// ============================================================================
// constants.asm - Shared Constants for HONDANI Shell
// ============================================================================
// This file contains all shared constants for the project.
// ============================================================================

// Runtime variables Zero page locations
.const SAVX = $02                  // 1 byte temp storage, often to save X register
.const ZP_INDIRECT_ADDR = $b2      // +$b3 Repurposable Zero page indirect address pointer 1
.const ZP_INDIRECT_ADDR_2 = $c1    // +$c2 Repurposable Zero page indirect address pointer 2
.const TMP2 = $c3                  // usually holds start address
.const PCH = $00                   // program counter high byte
.const PCL = $00                   // program counter low byte
.const REU_SIZE_BANKS = $FB        // Number of 64KB banks detected
.const InputBuffer  = $0200        // Input buffer in RAM (safe area page 3, 256 bytes)
.const parser_input_cursor = $0313 // Current position in parser input string
.const InputLength  = $033C        // Current length of input (in RAM - safe area)
.const CursorPos    = $033D        // Current cursor position (in RAM - safe area)

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
.const ENTER_KEY    = $0D
.const DELETE_KEY   = $14
.const CURSOR_LEFT  = $9D
.const CURSOR_RIGHT = $1D
.const SPACE_CHAR   = $20

.const KEY_NULL = $00
.const KEY_SPACE = $20
.const KEY_E = $45
.const KEY_H = $48
.const KEY_L = $4c
.const KEY_P = $50
.const KEY_R = $52
.const KEY_S = $53

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
.const PARSER_MAX_INPUT_LEN = 89 // Maximum length of user input
.const PARSER_WHITESPACE = $20 // ASCII space character used as whitespace in parser
.const PARSER_END_OF_TABLE = $FF // Special marker indicating end of parser token table