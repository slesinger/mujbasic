#import "constants.asm"
// ============================================================================
// init.asm - System Initialization for HONDANI Shell
// ============================================================================
// This file contains all initialization routines for the HONDANI Shell
// ============================================================================

// ============================================================================
// Constants
// ============================================================================

#import "constants.asm"

// ============================================================================
// Initialize System
// ============================================================================
// Called once at cold start to set up the system
// ============================================================================
InitSystem:
    jsr SetColors
    // jsr SetLowercaseMode
    jsr ClearScreen
    jsr InitInputBuffer
    jsr DetectREU
    jsr clear_history  // TODO load history from REU/network
    jsr clear_terminal_history
    InitGlobalVariables()
    jmp PrintWelcomeMessage     // Tail call optimization

// ============================================================================
// Initialize Input Buffer
// ============================================================================
// Clears the input buffer and resets counters
// Also enables cursor
// ============================================================================
InitInputBuffer:
    lda #0
    sta InputLength     // Clear InputLength
    sta CursorPos       // Clear CursorPos
    sta $CC             // Enable cursor (0 = enabled, 1+ = disabled)
    rts

// ============================================================================
// Clear Screen
// ============================================================================
// Uses KERNAL routine to clear screen
// ============================================================================
ClearScreen:
    jmp CLRSCR          // KERNAL clear screen routine (tail call)

// ============================================================================
// Set Screen Colors
// ============================================================================
// Sets border and background colors
// ============================================================================
SetColors:
    lda #LIGHT_BLUE
    sta BORDER_COLOR    // Set border color
    lda #BLUE
    sta BG_COLOR        // Set background color
    rts

// ============================================================================
// Set Lowercase Mode
// ============================================================================
// Switches to lowercase/uppercase character set
// ============================================================================
SetLowercaseMode:
    lda $D018           // Get VIC memory control register
    and #%11110001      // Clear character set bits (bits 1-3)
    ora #%00000110      // Set to lowercase/uppercase charset at $1800 (bits 2-1 = %11)
    sta $D018
    rts

// ============================================================================
// Setup REU Transfer
// ============================================================================
// Helper function to reduce redundant REU setup code
// Input: A = REU bank, X = command (C64->REU=$90, REU->C64=$91)
// Uses: $0200 for C64 base, $0000 for REU base, 1 byte length
// ============================================================================
SetupREUTransfer:
    sta REU_REU_BANK        // Set REU bank
    lda #$00
    sta REU_C64_ADDR_LO     // C64 address low
    sta REU_REU_ADDR_LO     // REU address low
    sta REU_REU_ADDR_HI     // REU address high
    lda #$02
    sta REU_C64_ADDR_HI     // C64 address high ($0200)
    lda #$01
    sta REU_LENGTH_LO       // Transfer 1 byte
    lda #$00
    sta REU_LENGTH_HI
    stx REU_COMMAND         // Execute command
    nop
    nop                     // Wait for transfer
    rts

// ============================================================================
// Detect REU
// ============================================================================
// Detects REU presence and size
// Stores number of 64KB banks in REU_SIZE_BANKS (0 if no REU)
// Standard sizes: 128KB=2, 256KB=4, 512KB=8, 1MB=16, 2MB=32, 4MB=64, 8MB=128
// ============================================================================
DetectREU:
    lda #$00
    sta REU_SIZE_BANKS

    // Simple detection: try to write/read a byte to REU
    lda #$AA
    sta $0200
    
    // Transfer TO REU (C64 -> REU)
    lda #$00                // Bank 0
    ldx #%10010000          // C64->REU command
    jsr SetupREUTransfer
    
    // Change C64 memory
    lda #$55
    sta $0200
    
    // Transfer FROM REU (REU -> C64)
    lda #$00                // Bank 0
    ldx #%10010001          // REU->C64 command
    jsr SetupREUTransfer

    // Check if we got original value back
    lda $0200
    cmp #$AA
    beq !detectedOK+
    jmp !noREU+
!detectedOK:

    // REU works! Now detect size by probing banks
    // Write marker $AA to bank 0, address $0000
    lda #$AA
    sta $0200
    lda #$00                // Bank 0
    ldx #%10010000          // C64->REU command
    jsr SetupREUTransfer
    
    // Now test each bank by writing its number to it
    ldy #$01                // Start at bank 1
!testBank:
    // Write bank number to C64 memory and transfer to current bank
    sty $0200
    sty $FC                 // Save bank counter in zero page
    
    tya
    ldx #%10010000          // C64->REU command
    jsr SetupREUTransfer
    
    // Read back from bank 0 to check if it still has $AA
    lda #$FF
    sta $0200
    lda #$00                // Bank 0
    ldx #%10010001          // REU->C64 command
    jsr SetupREUTransfer
    
    // If bank 0 doesn't have $AA anymore, we wrapped
    lda $0200
    cmp #$AA
    bne !sizeFound+
    
    // Bank exists, try next
    ldy $FC
    iny
    beq !maxSize+           // If wrapped to 0, that means we tested all 256 banks (16MB)
    cpy #129                // Safety check - shouldn't get here normally
    bcc !testBank-
    
!maxSize:
    lda #$FF                // 16MB (256 banks) - store special value
    .byte $2C               // BIT absolute - skip next 2 bytes
!sizeFound:
    lda $FC                 // Current bank count
    .byte $2C               // BIT absolute - skip next 2 bytes
!noREU:
    lda #$00
    sta REU_SIZE_BANKS
    rts

// ============================================================================
// Helper: Load Text Pointer
// ============================================================================
// Input: A = low byte, X = high byte
// Output: $02/$03 = pointer
// ============================================================================
LoadTextPtr:
    sta $02
    stx $03
    rts

// ============================================================================
// Fill commandline_history_addr ($c000 - $c400) buffer with spaces
// ============================================================================
// Input: None
// Output: None
// ============================================================================
clear_history:
    lda #SCR_SPACE
    ldx #$00
    stx commandline_history_idx
clear_history_loop:
    sta commandline_history_addr + $0000,x
    sta commandline_history_addr + $0100,x
    sta commandline_history_addr + $0200,x
    sta commandline_history_addr + $0300,x
    dex
    bne clear_history_loop
    stx commandline_history_idx  // set 0
    rts

// ============================================================================
// Fill terminal history in REU bank 0 $0000-$4000 buffer with spaces
// ============================================================================
// Input: None
// Output: None
// Kills: A
// ============================================================================
clear_terminal_history:
    lda #$00
    sta SAVX  // $9e
    sta SAVY  // $9f
    ReuFill(SCR_SPACE, $009e, 0, $4000)
    rts
// ============================================================================
// Print Welcome Message
// ============================================================================
// Prints banner with REU status and ready prompt
// ============================================================================
PrintWelcomeMessage:
    // Print base text "HDN Shell v0.1"
    lda #<WelcomeText
    ldx #>WelcomeText
    jsr LoadTextPtr
    jsr PrintText
    
    lda REU_SIZE_BANKS
    beq !noREU+
    
    // Print ", REU "
    lda #<REULabel
    ldx #>REULabel
    jsr LoadTextPtr
    jsr PrintText
    
    // Check if $FF (256 banks = 16MB)
    lda REU_SIZE_BANKS
    cmp #$FF
    bne !normalSize+
    lda #16
    jsr PrintDecimal
    jmp !printMB+
    
!normalSize:
    // Convert banks to MB (banks / 16)
    lda REU_SIZE_BANKS
    lsr
    lsr
    lsr
    lsr
    beq !printKB+
    jsr PrintDecimal
!printMB:
    lda #<MBText
    ldx #>MBText
    jsr LoadTextPtr
    jsr PrintText
    jmp !printReady+
    
!printKB:
    // For sizes < 1MB, handle common sizes with lookup table
    lda REU_SIZE_BANKS
    cmp #9
    bcs !notCommon+         // >= 9 banks, not a common size
    
    // Use lookup table for common sizes (2, 4, 8 banks)
    asl                     // * 2 for word lookup
    tax
    lda KBSizeTableLo-2,x   // -2 because table starts at bank 1
    sta $02
    lda KBSizeTableHi-2,x
    sta $03
    lda ($02),y             // Check if null (Y=0 from earlier)
    beq !notCommon+         // Not in table
    jsr PrintText
    jmp !printReady+
    
!notCommon:
    // For other sizes, calculate banks * 64
    lda REU_SIZE_BANKS
    asl                     // * 64
    asl
    asl
    asl
    asl
    asl
    jsr PrintDecimal
    lda #<KBText
    ldx #>KBText
    jsr LoadTextPtr
    jsr PrintText
    jmp !printReady+
    
!noREU:
    lda #<NoREUText
    ldx #>NoREUText
    jsr LoadTextPtr
    jsr PrintText
    
!printReady:
    // Print newline then "READY."
    lda #KEY_RETURN             // Carriage return
    jsr CHROUT
    jsr CHROUT
    lda #<ReadyText
    ldx #>ReadyText
    jsr LoadTextPtr
    jsr PrintText
    lda #KEY_RETURN             // Print another newline after READY.
    jsr CHROUT
    rts

// ============================================================================
// Print Text
// ============================================================================
// Prints null-terminated string using KERNAL CHROUT
// Input: $02/$03 = pointer to string
// ============================================================================
PrintText:
    ldy #$00
!loop:
    lda ($02),y
    beq !done+
    jsr CHROUT
    iny
    bne !loop-
!done:
    rts

// ============================================================================
// Print Decimal Number
// ============================================================================
// Prints 1-3 digit decimal number using KERNAL CHROUT
// Input: A = number (0-255)
// ============================================================================
PrintDecimal:
    ldx #0              // Leading zero flag
    
    // Hundreds digit
    ldy #0
!hundreds:
    cmp #100
    bcc !tens+
    sbc #100            // Carry already set from compare
    iny
    bne !hundreds-
!tens:
    cpy #0
    beq !tensCalc+
    pha
    tya
    ora #$30
    jsr CHROUT
    ldx #1              // Set leading zero flag
    pla
    
!tensCalc:
    // Tens digit
    ldy #0
!tensLoop:
    cmp #10
    bcc !ones+
    sbc #10
    iny
    bne !tensLoop-
!ones:
    cpx #0              // Check leading zero flag
    bne !printTens+
    cpy #0
    beq !onesCalc+
!printTens:
    pha
    tya
    ora #$30
    jsr CHROUT
    pla
    
!onesCalc:
    // Ones digit always printed
    ora #$30
    jmp CHROUT          // Tail call optimization

// ============================================================================
// Text Data
// ============================================================================
// Using petscii encoding for CHROUT (not screen codes)
.encoding "petscii_mixed"

WelcomeText:
    // .text "HDN SHELL V0.1"
    .text "hdn shell v0.1"
    .byte $00

REULabel:
    // .text ", REU "
    .text ", reu "
    .byte $00

MBText:
    // .text "MB"
    .text "mb"
    .byte $00

KBText:
    // .text "KB"
    .text "kb"
    .byte $00

Msg128KB:
    .text "128kb"
    .byte $00

Msg256KB:
    .text "256kb"
    .byte $00

Msg512KB:
    .text "512kb"
    .byte $00

NoREUText:
    // .text ", no REU found"
    .text ", no reu found"
    .byte $00

ReadyText:
    // .text "READY."
    .text "ready."
    .byte $00

// Lookup table for common KB sizes (indexed by bank count * 2)
KBSizeTableLo:
    .byte $00, <Msg128KB, $00, <Msg256KB, $00, $00, $00, <Msg512KB
KBSizeTableHi:
    .byte $00, >Msg128KB, $00, >Msg256KB, $00, $00, $00, >Msg512KB
