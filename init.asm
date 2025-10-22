// ============================================================================
// init.asm - System Initialization for HONDANI Shell
// ============================================================================
// This file contains all initialization routines for the HONDANI Shell
// ============================================================================

// ============================================================================
// Constants
// ============================================================================
.const SCREEN_RAM   = $0400     // Screen memory start
.const COLOR_RAM    = $D800     // Color memory start
.const BORDER_COLOR = $D020     // Border color register
.const BG_COLOR     = $D021     // Background color register

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

// ============================================================================
// Initialize System
// ============================================================================
// Called once at cold start to set up the system
// ============================================================================
InitSystem:
    jsr SetColors
    jsr SetLowercaseMode
    jsr ClearScreen
    jsr DetectREU
    jsr PrintWelcomeMessage
    rts

// ============================================================================
// Clear Screen
// ============================================================================
// Fills screen memory with spaces (character code $20)
// ============================================================================
ClearScreen:
    ldx #$00
    lda #$20            // Space character
!loop:
    sta SCREEN_RAM,x         // Screen RAM page 1
    sta SCREEN_RAM + $100,x  // Screen RAM page 2
    sta SCREEN_RAM + $200,x  // Screen RAM page 3
    sta SCREEN_RAM + $300,x  // Screen RAM page 4
    inx
    bne !loop-
    rts

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
// Input: A = C64 addr high, X = REU bank, Y = command
// Uses: $0200 for C64 base, $0000 for REU base, 1 byte length
// ============================================================================
SetupREUTransfer:
    pha                     // Save C64 addr high
    lda #$00
    sta $DF0A               // Clear control register
    sta $DF04               // REU base address low
    sta $DF05               // REU base address high
    sta $DF02               // C64 base address low
    lda #$01
    sta $DF07               // Transfer length = 1 byte
    lda #$00
    sta $DF08               // Transfer length high
    stx $DF06               // Set REU bank
    pla
    sta $DF03               // Set C64 base address high
    sty $DF01               // Execute command
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
    
    // Setup transfer TO REU (C64 -> REU)
    lda #$00
    sta REU_C64_ADDR_LO     // C64 address low = $00
    lda #$02
    sta REU_C64_ADDR_HI     // C64 address high = $02 ($0200)
    lda #$00
    sta REU_REU_ADDR_LO     // REU address low = $00
    sta REU_REU_ADDR_HI     // REU address high = $00
    sta REU_REU_BANK        // REU bank = 0
    lda #$01
    sta REU_LENGTH_LO       // Transfer 1 byte
    lda #$00
    sta REU_LENGTH_HI
    lda #%10010000          // Execute: C64->REU, no autoload
    sta REU_COMMAND

    // Wait for transfer to complete
    nop
    nop
    
    // Change C64 memory
    lda #$55
    sta $0200
    
    // Setup transfer FROM REU (REU -> C64) - need to re-setup addresses
    lda #$00
    sta REU_C64_ADDR_LO     // C64 address low = $00
    lda #$02
    sta REU_C64_ADDR_HI     // C64 address high = $02 ($0200)
    lda #$00
    sta REU_REU_ADDR_LO     // REU address low = $00
    sta REU_REU_ADDR_HI     // REU address high = $00
    sta REU_REU_BANK        // REU bank = 0
    lda #$01
    sta REU_LENGTH_LO       // Transfer 1 byte
    lda #$00
    sta REU_LENGTH_HI
    lda #%10010001          // Execute: REU->C64, no autoload
    sta REU_COMMAND

    // Wait for transfer to complete
    nop
    nop

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
    lda #$00
    sta REU_C64_ADDR_LO
    lda #$02
    sta REU_C64_ADDR_HI
    lda #$00
    sta REU_REU_ADDR_LO
    sta REU_REU_ADDR_HI
    sta REU_REU_BANK        // Bank 0
    lda #$01
    sta REU_LENGTH_LO
    lda #$00
    sta REU_LENGTH_HI
    lda #%10010000          // C64->REU
    sta REU_COMMAND
    nop
    nop
    
    // Now test each bank by writing its number to it
    ldx #$01                // Start at bank 1
!testBank:
    // Write bank number to C64 memory
    stx $0200
    stx $FC                 // Save bank counter in zero page
    
    // Transfer bank number to current bank
    lda #$00
    sta REU_C64_ADDR_LO
    lda #$02
    sta REU_C64_ADDR_HI
.break
    lda #$00
    sta REU_REU_ADDR_LO
    sta REU_REU_ADDR_HI
    stx REU_REU_BANK        // Current bank being tested
    lda #$01
    sta REU_LENGTH_LO
    lda #$00
    sta REU_LENGTH_HI
    lda #%10010000          // C64->REU
    sta REU_COMMAND
    nop
    nop
    
    // Read back from bank 0 to check if it still has $AA
    lda #$FF
    sta $0200
    lda #$00
    sta REU_C64_ADDR_LO
    lda #$02
    sta REU_C64_ADDR_HI
    lda #$00
    sta REU_REU_ADDR_LO
    sta REU_REU_ADDR_HI
    sta REU_REU_BANK        // Bank 0
    lda #$01
    sta REU_LENGTH_LO
    lda #$00
    sta REU_LENGTH_HI
    lda #%10010001          // REU->C64
    sta REU_COMMAND
    nop
    nop
    
    // If bank 0 doesn't have $AA anymore, we wrapped
    lda $0200
    cmp #$AA
    beq !bankOK+
    jmp !sizeFound+
!bankOK:
    
    // Bank exists, try next
    ldx $FC
    inx
    beq !maxSize+           // If wrapped to 0, that means we tested all 256 banks (16MB)
    cpx #129                // Safety check - shouldn't get here normally
    bcc !testBank-
    
!maxSize:
    // Hit 16MB (256 banks) - store special value $FF
    ldx #$FF
    stx REU_SIZE_BANKS
    rts
    
!sizeFound:
    ldx $FC                 // Current bank count
    stx REU_SIZE_BANKS
    rts
    
!noREU:
    lda #$00
    sta REU_SIZE_BANKS
    rts

// ============================================================================
// Print Welcome Message
// ============================================================================
// Prints banner with REU status and ready prompt
// ============================================================================
PrintWelcomeMessage:
    ldx #$00
    
    // Print base text "Hondani Shell v0.1"
!printBase:
    lda WelcomeText,x
    beq !checkREU+
    sta SCREEN_RAM,x
    lda #WHITE
    sta COLOR_RAM,x
    inx
    jmp !printBase-
    
.break
!checkREU:
    lda REU_SIZE_BANKS
    bne !hasREU+
    jmp !noREU+
.break
    
!hasREU:
    
    // Print ", reu "
    lda #<REULabel
    sta $02
    lda #>REULabel
    sta $03
    jsr PrintText
    
    // Check if $FF (256 banks = 16MB)
    lda REU_SIZE_BANKS
    cmp #$FF
    bne !normalSize+
    
    // Print 16MB
    lda #16
    jsr PrintDecimal
    lda #<MBText
    sta $02
.break
    lda #>MBText
    sta $03
    jsr PrintText
    jmp !printReady+
    
!normalSize:
    // Convert banks to MB (banks / 16)
    lda REU_SIZE_BANKS
    lsr
    lsr
    lsr
    lsr
    beq !printKB+
    
    // Print size in MB
    jsr PrintDecimal
    lda #<MBText
    sta $02
    lda #>MBText
    sta $03
    jsr PrintText
    jmp !printReady+
    
!printKB:
    // For sizes < 1MB, we have 2-15 banks (128KB-960KB)
    // Let's just handle specific common sizes
    lda REU_SIZE_BANKS
    cmp #2
    bne !not128+
    lda #<Msg128KB
    sta $02
    lda #>Msg128KB
    sta $03
    jsr PrintText
    jmp !printReady+
    
!not128:
    cmp #4
    bne !not256+
    lda #<Msg256KB
    sta $02
    lda #>Msg256KB
    sta $03
    jsr PrintText
    jmp !printReady+
    
!not256:
    cmp #8
    bne !notCommon+
    lda #<Msg512KB
    sta $02
    lda #>Msg512KB
    sta $03
    jsr PrintText
    jmp !printReady+
    
!notCommon:
    // For other sizes, print banks * 64 using lookup or calculation
    // For simplicity, just show number of banks
    lda REU_SIZE_BANKS
    asl                     // * 2
    asl                     // * 4  
    asl                     // * 8
    asl                     // * 16
    asl                     // * 32
    asl                     // * 64 - this will wrap but works for small values
    jsr PrintDecimal
    lda #<KBText
    sta $02
    lda #>KBText
    sta $03
    jsr PrintText
    jmp !printReady+
    
!noREU:
    lda #<NoREUText
    sta $02
    lda #>NoREUText
    sta $03
    jsr PrintText
    
!printReady:
    // Print "ready." on second line
    lda #<ReadyText
    sta $02
    lda #>ReadyText
    sta $03
    ldx #40
    jsr PrintText
    rts

// ============================================================================
// Print Character with Color
// ============================================================================
// Helper to write char and color in one call
// Input: A = character, X = screen position
// Output: X = incremented position
// ============================================================================
PrintChar:
    sta SCREEN_RAM,x
    pha
    lda #WHITE
    sta COLOR_RAM,x
    pla
    inx
    rts

// ============================================================================
// Print Text
// ============================================================================
// Prints null-terminated string at current screen position
// Input: $02/$03 = pointer to string, X = screen position
// Output: X = updated position
// ============================================================================
PrintText:
    ldy #$00
!loop:
    lda ($02),y
    beq !done+
    jsr PrintChar
    iny
    bne !loop-
!done:
    rts

// ============================================================================
// Print Decimal Number
// ============================================================================
// Prints 1-3 digit decimal number at current screen position
// Input: A = number (0-255), X = screen position
// Output: X = updated position after digits
// ============================================================================
PrintDecimal:
    sta $02             // Store number
    lda #$00
    sta $03             // Clear leading zero flag
    
    // Hundreds digit
    lda $02
    ldy #$00
!hundreds:
    cmp #100
    bcc !tens+
    sbc #100
    iny
    jmp !hundreds-
!tens:
    sta $02
    cpy #$00
    beq !tensCalc+
    tya
    ora #$30
    jsr PrintChar
    inc $03             // Set leading zero flag
    
!tensCalc:
    // Tens digit
    lda $02
    ldy #$00
!tensLoop:
    cmp #10
    bcc !ones+
    sbc #10
    iny
    jmp !tensLoop-
!ones:
    sta $02
    lda $03
    bne !printTens+
    cpy #$00
    beq !onesCalc+
!printTens:
    tya
    ora #$30
    jsr PrintChar
    
!onesCalc:
    // Ones digit
    lda $02
    ora #$30
    jsr PrintChar
    rts

// ============================================================================
// Text Data
// ============================================================================
WelcomeText:
    .text "Hondani Shell v0.1"
    .byte $00

REULabel:
    .text ", REU "
    .byte $00

MBText:
    .text "MB"
    .byte $00

KBText:
    .text "KB"
    .byte $00

Msg128KB:
    .text "128KB"
    .byte $00

Msg256KB:
    .text "256KB"
    .byte $00

Msg512KB:
    .text "512KB"
    .byte $00

NoREUText:
    .text ", no REU found"
    .byte $00

ReadyText:
    .text "READY."
    .byte $00
