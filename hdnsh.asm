#import "constants.asm"  // does not generate any bytes here

// ============================================================================
// HONDANI Shell - Custom BASIC ROM Replacement for Commodore 64
// ============================================================================
// This ROM replaces the built-in BASIC interpreter at $A000-$BFFF
// Version: 0.1.0
// ============================================================================

.file [name="hdnsh.bin", type="bin", segments="BasicROM"]

// BASIC ROM is located at $A000-$BFFF (8KB)
.segmentdef BasicROM [start=$A000, min=$A000, max=$BFFF, fill]

.segment BasicROM

// ============================================================================
// Cold Start Vector - MUST be at $A000
// ============================================================================
// The C64 KERNAL reads the 16-bit address at $A000-$A001 and jumps there
// ============================================================================

.word ColdStart         // Cold start vector at $A000-$A001
.word ColdStart         // Warm start vector at $A002-$A003 (same as cold for now)

// ============================================================================
// Entry Points
// ============================================================================

ColdStart:
    // Register BRK handler
//     lda #<break_handler         // set BRK vector
//     sta BKVEC
//     lda #>break_handler
//     sta BKVEC+1

break_handler:  // id BRK is encountered, system "like" restarts and you run "r" to dispay registers
    // BreakHandler()              // save registers to handle BRK

    jsr InitSystem      // Initialize the system
    jmp MainLoop        // Enter main loop

// ============================================================================
// Constants and Variables
// ============================================================================

#import "constants.asm"

// ============================================================================
// Include Input Handling Routines
// ============================================================================
#import "input.asm"

// ============================================================================
// Main Loop
// ============================================================================
// Main event loop - waits for user input and processes commands
// ============================================================================

MainLoop:
    jsr GETIN           // Get character from keyboard buffer
    beq MainLoop        // No key pressed, keep looping
    jsr HandleInput     // Process the input character
    jmp MainLoop


// ============================================================================
// Include initialization routines
// ============================================================================
#import "init.asm"

// ============================================================================
// BASIC ROM Vector Table (must be at specific addresses)
// ============================================================================
// The KERNAL expects certain vectors at specific locations in the BASIC ROM
// ============================================================================

.pc = $BF80 "Vector Table"
.fill 16, $00           // Standard BASIC ROM vectors (8 words)

.pc = $BFA0
// Function vectors - BASIC warm start is the key one
.word ColdStart         // BASIC warm start
.fill 14, $00           // Unused vectors (7 words)

// ============================================================================
// ROM Signature
// ============================================================================
.pc = $BFEC
.text "hondani shell 0.1"
