#importonce
// ============================================================================
// constants.asm - Shared Constants for HONDANI Shell
// ============================================================================
// This file contains all shared constants for the project.
// ============================================================================



// KERNAL routines
.const GETIN        = $FFE4     // KERNAL get character from keyboard
.const CHROUT       = $FFD2     // KERNAL character output
.const CLRSCR      = $E544     // KERNAL clear screen routine

// Input buffer and related variables
.const InputBuffer  = $0340     // Input buffer in RAM (safe area page 3, 256 bytes)
.const InputLength  = $033C     // Current length of input (in RAM - safe area)
.const CursorPos    = $033D     // Current cursor position (in RAM - safe area)
.const INPUT_LINE_BUFFER = $1000 // Input line buffer destination

// Input key codes
.const ENTER_KEY    = 13
.const DELETE_KEY   = 20
.const CURSOR_LEFT  = 157
.const CURSOR_RIGHT = 29
.const SPACE_CHAR   = 32

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

// Runtime variables (stored in zero page)
.const REU_SIZE_BANKS  = $FB    // Number of 64KB banks detected

// MujBASIC working area
.const MUJBASIC_CURRENT_DRIVE = $0313 // Current drive number used as default for listing directory and file operations