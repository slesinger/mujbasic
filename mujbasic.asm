// ============================================================================
// HONDANI Shell - Custom BASIC ROM Replacement for Commodore 64
// ============================================================================
// This ROM replaces the built-in BASIC interpreter at $A000-$BFFF
// Version: 0.1.0
// ============================================================================

.file [name="mujbasic.bin", type="bin", segments="BasicROM"]

// BASIC ROM is located at $A000-$BFFF (8KB)
.segmentdef BasicROM [start=$A000, min=$A000, max=$BFFF, fill]

.segment BasicROM

// ============================================================================
// Cold Start Vector - MUST be at $A000
// ============================================================================
// The C64 KERNAL reads the 16-bit address at $A000-$A001 and jumps there
// ============================================================================

.word ColdStart         // Cold start vector at $A000-$A001
.word WarmStart         // Warm start vector at $A002-$A003

// ============================================================================
// Entry Points
// ============================================================================

ColdStart:
    jsr InitSystem      // Initialize the system
    jmp MainLoop        // Enter main loop

WarmStart:
    // For now, warm start does the same as cold start
    jmp ColdStart

// ============================================================================
// Main Loop
// ============================================================================
// Main event loop - waits for user input and processes commands
// ============================================================================

MainLoop:
    // TODO: Wait for keyboard input
    // TODO: Process commands
    jmp MainLoop        // Loop forever

// ============================================================================
// Include initialization routines
// ============================================================================
#import "init.asm"

// ============================================================================
// BASIC ROM Vector Table (must be at specific addresses)
// ============================================================================
// The KERNAL expects certain vectors at specific locations in the BASIC ROM
// The cold start vector at $A000 is jumped to during system initialization
// ============================================================================

.pc = $BF80 "Vector Table"
// Standard BASIC ROM vectors
.word $0000, $0000, $0000, $0000
.word $0000, $0000, $0000, $0000

.pc = $BFA0
// Function vectors - BASIC warm start is the key one
.word ColdStart         // BASIC warm start - point to our cold start
.word $0000             // CHRGET routine
.word $0000             // CHRGOT routine
.word $0000, $0000, $0000, $0000, $0000

// ============================================================================
// ROM Signature
// ============================================================================
.pc = $BFEC
.text "hondani shell 0.1"
