// ============================================================================
// Input Text Handling Routine
// ============================================================================
// Handles keyboard input with cursor movement, insertion, and deletion
// Requires: InputBuffer, InputLength, CursorPos to be defined in main file
// ============================================================================

// Constants

#import "constants.asm"
#import "input_dispatch.asm"
// ============================================================================
// Main Input Handler
// ============================================================================
// Processes keyboard input and manages the input buffer
// Called from main loop with character in A register
// ============================================================================

HandleInput:
    // Handle special keys
    cmp #ENTER_KEY
    bne !+
    jmp HandleEnter
!:  cmp #DELETE_KEY
    bne !+
    jmp HandleDelete
!:  cmp #CURSOR_LEFT
    bne !+
    jmp HandleCursorLeft
!:  cmp #CURSOR_RIGHT
    bne !+
    jmp HandleCursorRight
!:
    
    // Regular character - insert at cursor position
    ldx InputLength
    cpx #255          // Max buffer size check
    beq InputDone       // Buffer full, ignore
    
    // Save character temporarily
    pha
    
    // Check if we need to insert (cursor not at end)
    ldx CursorPos
    cpx InputLength
    beq InsertAtEnd     // Cursor at end, just append
    
    // Shift characters right to make space
    ldy InputLength     // Start from end
ShiftLoop:
    dey
    cpy CursorPos
    bcc ShiftDone       // Done when Y < CursorPos
    lda InputBuffer,y
    sta InputBuffer+1,y
    jmp ShiftLoop
    
ShiftDone:
InsertAtEnd:
    // Insert character at cursor position to input buffer
    pla
    ldx CursorPos
    sta InputBuffer,x
    
    // Check if we inserted at the end
    cpx InputLength
    beq InsertedAtEnd
    
    // Inserted in middle - need to redraw entire line from insertion point
    inc InputLength
    
    // Save original cursor position
    lda CursorPos
    pha
    
    // Redraw: print from cursor pos to end
    ldx CursorPos
RedrawInsert:
    cpx InputLength
    bcs RedrawInsertDone
    lda InputBuffer,x
    jsr CHROUT
    inx
    jmp RedrawInsert
    
RedrawInsertDone:
    // Print space to clear old character
    lda #SPACE_CHAR
    jsr CHROUT
    
    // Calculate how many positions to move back
    // We printed (InputLength - CursorPos) chars + 1 space
    // We want cursor at CursorPos + 1
    // So move back: (InputLength - CursorPos + 1) - 1 = InputLength - CursorPos
    pla                 // Get original cursor position
    tax
    inx                 // Target position = CursorPos + 1
    stx CursorPos       // Update CursorPos
    
    lda InputLength
    sec
    sbc CursorPos
    tax
    inx                 // +1 for the space
    
MoveBackInsert:
    beq DoneInsert
    lda #CURSOR_LEFT
    jsr CHROUT
    dex
    jmp MoveBackInsert
    
DoneInsert:
    rts
    
InsertedAtEnd:
    // Simply print the character and update counters
    jsr CHROUT          // Character is still in A
    inc InputLength
    inc CursorPos
InputDone:
    rts

// ============================================================================
// Handle Enter Key
// ============================================================================
HandleEnter:
    // Copy input buffer to $1000
    lda InputLength
    beq EmptyInput      // Skip copy if empty
    
    ldx #0
CopyLoop:
    lda InputBuffer,x
    sta INPUT_LINE_BUFFER,x
    inx
    cpx InputLength
    bcc CopyLoop        // Continue while X < InputLength
    
EmptyInput:
    // Null terminate
    lda #0
    ldx InputLength
    sta INPUT_LINE_BUFFER,x
    
    // Clear input buffer and reset cursor
    sta InputLength
    sta CursorPos
    
    // Print newline
    lda #ENTER_KEY
    jsr CHROUT


    // Dispatch the input line as a command
    jsr InputDispatch

    jsr PrintResponse

    rts
// ============================================================================
// Print Response Routine
// ============================================================================
// Prints null-terminated string at $1000 using CHROUT
// ============================================================================
PrintResponse:
    ldy #0
PrintResponseLoop:
    lda $1000,y
    beq PrintResponseDone
    jsr CHROUT
    iny
    bne PrintResponseLoop
PrintResponseDone:
    lda #ENTER_KEY // newline (carriage return)
    jsr CHROUT
    rts

// ============================================================================
// Handle Delete Key
// ============================================================================
HandleDelete:
    // Check if cursor position is at start
    lda CursorPos
    bne !canDelete+
    rts                 // At start, nothing to delete
!canDelete:
    
    // Delete character before cursor
    dec CursorPos
    
    // Shift characters left
    ldx CursorPos
DeleteShiftLoop:
    cpx InputLength
    bcs DeleteShiftDone
    lda InputBuffer+1,x
    sta InputBuffer,x
    inx
    jmp DeleteShiftLoop
    
DeleteShiftDone:
    dec InputLength
    
    // Move cursor back visually
    // lda #CURSOR_LEFT
    // jsr CHROUT
    
    // Redraw from current cursor position to end
    ldx CursorPos
RedrawDelete:
    cpx InputLength
    bcs RedrawDeleteClear
    lda InputBuffer,x
    jsr CHROUT
    inx
    jmp RedrawDelete
    
RedrawDeleteClear:
    // Print space to clear the deleted character
    lda #SPACE_CHAR
    jsr CHROUT
    
    // Move cursor back to correct position
    lda InputLength
    sec
    sbc CursorPos
    beq DoneDelete
    tax
MoveBackDelete:
    lda #CURSOR_LEFT
    jsr CHROUT
    dex
    bne MoveBackDelete
    
DoneDelete:
    rts

// ============================================================================
// Handle Cursor Left
// ============================================================================
HandleCursorLeft:
    lda CursorPos
    beq !done+          // At start, can't go left
    dec CursorPos
    lda #CURSOR_LEFT
    jsr CHROUT
!done:
    rts

// ============================================================================
// Handle Cursor Right
// ============================================================================
HandleCursorRight:
    lda CursorPos
    cmp InputLength
    bcs !done+          // At or beyond end of input, can't go right
    inc CursorPos
    lda #CURSOR_RIGHT
    jsr CHROUT
!done:
    rts
