#importonce
// ============================================================================
// constants.asm - Shared Constants for HONDANI Shell
// ============================================================================
// This file contains all shared constants for the project.
// This file should only contain definitions, no code, no data.
// ============================================================================

// Runtime variables Zero page locations
.const _TMP = $02                 // 1 byte temp storage
.const SAVX = $9e                  // 1 byte temp storage, often to save X register
.const SAVY = $9f                  // 1 byte temp storage, often to save Y register
.const ZP_INDIRECT_ADDR = $b2      // +$b3 Repurposable Zero page indirect address pointer 1
.const FNLEN = $B7                 // length of current filename
.const SADD = $B9                  // current secondary address (official name SA) like, load "*",8,1 <- put 1 into SADD
.const FA = $BA                    // current device number
.const FNADR = $BB                 // $00BB-$00BC pointer to current filename
.const ZP_INDIRECT_ADDR_2 = $c1    // +$c2 Repurposable Zero page indirect address pointer 2
.const TMP0 = $c1                  // +$c2 Repurposable Zero page indirect address pointer 2 used in SMON
.const TMP2 = $c3                  // usually holds start address
.const REU_SIZE_BANKS = $FB        // Number of 64KB banks detected

// 8 bytes $0334-$033B global vars Eight free bytes for user vectors or other data.
// Next 7 bytes must follow in this order, do not change order!
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
.const CursorPos = $033D        // Current cursor position within user input line (in RAM - safe area)
.const DIGCNT = $033e              // digit counter for RDVAL
.const NUMBIT = $033f              // number of bits per digit for RDVAL
.const INDIG = $0340               // input digit value for RDVAL
.const STASH = $0341               // and $0342 stashed character for RDVAL
.const U0AA0 = $0341               // .FILL 10 work buffer
.const U0AAE = U0AA0+10            // end of work buffer

// Read-only system constants
.const PNT = $d1                   // Read-only $00D1-$00D2	PNT	Pointer to the Address of the Current Screen Line
.const PNTR = $d3                  // Read-only $00D3	PNTR	Cursor Column on Current Line 0-79
.const BKVEC = $0316               // BRK instruction vector (official name CBINV)



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
.const KEY_CTRL_J = $0A
.const KEY_RETURN = $0D
.const KEY_HOME = $13
.const KEY_DELETE = $14
.const KEY_CURSOR_RIGHT = $1D
.const KEY_GREEN = $1E
.const KEY_BLUE = $1F
.const KEY_SPACE = $20
.const KEY_EXCLAMATION = $21
.const KEY_QUOTE = $22
.const KEY_HASH = $23
.const KEY_DOLLAR = $24
.const KEY_PERCENT = $25
.const KEY_AMPERSAND = $26
.const KEY_SINGLE_QUOTE = $27
.const KEY_OPEN_PAREN = $28
.const KEY_CLOSE_PAREN = $29
.const KEY_ASTERISK = $2a
.const KEY_PLUS = $2b
.const KEY_COMMA = $2c
.const KEY_MINUS = $2d
.const KEY_DOT = $2e
.const KEY_SLASH = $2f
.const KEY_0 = $30
.const KEY_1 = $31
.const KEY_2 = $32
.const KEY_3 = $33
.const KEY_4 = $34
.const KEY_5 = $35
.const KEY_6 = $36
.const KEY_7 = $37
.const KEY_8 = $38
.const KEY_9 = $39
.const KEY_COLON = $3a
.const KEY_SEMICOLON = $3b
.const KEY_LESS_THAN = $3c
.const KEY_EQUAL = $3d
.const KEY_GREATER_THAN = $3e
.const KEY_QUESTION_MARK = $3f
.const KEY_AT = $40
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


// Screen Codes
.const SCR_AMPERSAND = $00
.const SCR_Aa = $01
.const SCR_Bb = $02
.const SCR_Cc = $03
.const SCR_Dd = $04
.const SCR_Ee = $05
.const SCR_Ff = $06
.const SCR_Gg = $07
.const SCR_Hh = $08
.const SCR_Ii = $09
.const SCR_Jj = $0A
.const SCR_Kk = $0B
.const SCR_Ll = $0C
.const SCR_Mm = $0D
.const SCR_Nn = $0E
.const SCR_Oo = $0F
.const SCR_Pp = $10
.const SCR_Qq = $11
.const SCR_Rr = $12
.const SCR_Ss = $13
.const SCR_Tt = $14
.const SCR_Uu = $15
.const SCR_Vv = $16
.const SCR_Ww = $17
.const SCR_Xx = $18
.const SCR_Yy = $19
.const SCR_Zz = $1A
.const SCR_OPEN_SQUARE_BRACKET = $1B
.const SCR_POUND = $1C
.const SCR_CLOSE_SQUARE_BRACKET = $1D
.const SCR_ARROW_UP = $1E
.const SCR_ARROW_LEFT = $1F
.const SCR_SPACE = $20
.const SCR_EXCLAMATION = $21
.const SCR_QUOTE = $22
.const SCR_HASH = $23
.const SCR_DOLLAR = $24
.const SCR_PERCENT = $25
.const SCR_OPEN_BRACKET = $28
.const SCR_CLOSE_BRACKET = $29
.const SCR_ASTERISK = $2A
.const SCR_PLUS = $2B
.const SCR_COMMA = $2C
.const SCR_MINUS = $2D
.const SCR_DOT = $2E
.const SCR_SLASH = $2F
.const SCR_0 = $30
.const SCR_1 = $31
.const SCR_2 = $32
.const SCR_3 = $33
.const SCR_4 = $34
.const SCR_5 = $35
.const SCR_6 = $36
.const SCR_7 = $37
.const SCR_8 = $38
.const SCR_9 = $39
.const SCR_COLON = $3A
.const SCR_SEMICOLON = $3B
.const SCR_LESS_THAN = $3C
.const SCR_EQUAL = $3D
.const SCR_GREATER_THAN = $3E
.const SCR_QUESTION_MARK = $3F

.const SCR_RVS_AMPERSAND = $80
.const SCR_RVS_Aa = $81


// Screen and color RAM
.const SCREEN_RAM   = $0400     // Screen memory start
.const COLOR_RAM    = $D800     // Color memory start
.const BORDER_COLOR = $D020     // Border color register
.const BG_COLOR     = $D021     // Background color register

// Colors
.const BLACK        = $00
.const WHITE        = $01
.const RED          = $02
.const CYAN         = $03
.const PURPLE       = $04
.const GREEN        = $05
.const BLUE         = $06
.const YELLOW       = $07
.const ORANGE       = $08
.const BROWN        = $09
.const LIGHT_RED    = $0A
.const DARK_GRAY    = $0B
.const GRAY         = $0C
.const LIGHT_GREEN  = $0D
.const LIGHT_BLUE   = $0E
.const LIGHT_GRAY   = $0F

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
.const PARSER_INPUT_PTR = $0200  // BASIC line input buffer start
.const PARSER_MAX_INPUT_LEN = 79 // Maximum length of user input
.const PARSER_WHITESPACE = $20 // ASCII space character used as whitespace in parser
.const PARSER_END_OF_TABLE = $FF // Special marker indicating end of parser token table


// MACROS

.macro ParsingInputsDone() {
    lda #KEY_RETURN
    jsr CHROUT
}

.macro CommandDone() {
    jmp parse_done
}


// BRK handler
.macro BreakHandler() {
    ldx #$05            // pull registers off the stack
BSTACK:
    pla                 // order: Y,X,A,SR,PCL,PCH
    sta PCH,X           // store in memory
    dex 
    bpl BSTACK

// // put back the stack
ldx #$00            // start with YR
BUNSTACK:
    lda PCH,X       // load from memory (YR, XR, ACC, SR, PCL, PCH)
    pha             // push onto stack
    inx
    cpx #$06
    bne BUNSTACK

    cld                 // disable bcd mode
    tsx                 // store stack pointer in memory 
    ldx SP  // TODO muzu to dat pryc? L A*   G $080D
    stx SP
    cli                 // enable interupts
}
