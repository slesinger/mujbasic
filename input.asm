// ============================================================================
// Input Text Handling Routine
// ============================================================================
// Handles keyboard input with cursor movement, insertion, and deletion
// Requires: PARSER_INPUT_PTR, InputLength, CursorPos to be defined in main file
// ============================================================================

// Constants

#import "constants.asm"
#import "parser.asm"
// ============================================================================
// Main Input Handler
// ============================================================================
// Processes keyboard input and manages the input buffer
// Called from main loop with character in A register
// ============================================================================

HandleInput:
    // Handle special keys
    cmp #KEY_RETURN
    bne !+
    jmp HandleReturn
!:
    jsr CHROUT
    rts
// cmp #KEY_DELETE
//     bne !+
//     jmp HandleDelete
// !:  cmp #KEY_CURSOR_LEFT
//     bne !+
//     jmp HandleCursorLeft
// !:  cmp #KEY_CURSOR_RIGHT
//     bne !+
//     jmp HandleCursorRight
// !:
//     // Regular character - insert at cursor position
//     ldx InputLength
//     cpx #PARSER_MAX_INPUT_LEN   // Max buffer size check
//     beq InputDone       // Buffer full, ignore
//     // Save character temporarily
//     pha
//     // Check if we need to insert (cursor not at end)
//     ldx CursorPos
//     cpx InputLength
//     beq InsertAtEnd     // Cursor at end, just append
    
//     // Shift characters right to make space
//     ldy InputLength     // Start from end
// ShiftLoop:
//     dey
//     cpy CursorPos
//     bcc ShiftDone       // Done when Y < CursorPos
//     lda PARSER_INPUT_PTR,y
//     sta PARSER_INPUT_PTR+1,y
//     jmp ShiftLoop
    
// ShiftDone:
// InsertAtEnd:
//     // Insert character at cursor position to input buffer
//     pla
//     ldx CursorPos
//     sta PARSER_INPUT_PTR,x
//     // Check if we inserted at the end
//     cpx InputLength
//     beq InsertedAtEnd
    
//     // Inserted in middle - need to redraw entire line from insertion point
//     inc InputLength
    
//     // Save original cursor position
//     lda CursorPos
//     pha
    
//     // Redraw: print from cursor pos to end
//     ldx CursorPos
// RedrawInsert:
//     cpx InputLength
//     bcs RedrawInsertDone
//     lda PARSER_INPUT_PTR,x
//     jsr CHROUT
//     inx
//     jmp RedrawInsert
    
// RedrawInsertDone:
//     // Print space to clear old character
//     lda #KEY_SPACE
//     jsr CHROUT
    
//     // Calculate how many positions to move back
//     // We printed (InputLength - CursorPos) chars + 1 space
//     // We want cursor at CursorPos + 1
//     // So move back: (InputLength - CursorPos + 1) - 1 = InputLength - CursorPos
//     pla                 // Get original cursor position
//     tax
//     inx                 // Target position = CursorPos + 1
//     stx CursorPos       // Update CursorPos
    
//     lda InputLength
//     sec
//     sbc CursorPos
//     tax
//     inx                 // +1 for the space
    
// MoveBackInsert:
//     beq DoneInsert
//     lda #KEY_CURSOR_LEFT
//     jsr CHROUT
//     dex
//     jmp MoveBackInsert
    
// DoneInsert:
//     rts
    
// InsertedAtEnd:
//     // Simply print the character and update counters
//     jsr CHROUT          // Character is still in A
//     inc InputLength
//     inc CursorPos
// InputDone:
//     rts

// ============================================================================
// Handle Enter Key
// ============================================================================
HandleReturn:
    // copy input from screen current line to PARSER_INPUT_PTR, max 79 chars
    ldy #79
CopyInputLoop:
    lda (PNT),y        // read from current screen input line
    jsr screen2petscii
    sta PARSER_INPUT_PTR,y   // store to input buffer
    dey
    cpy #$ff
    beq CopyInputLoopEnd
    jmp CopyInputLoop
CopyInputLoopEnd:
    
    // // Null terminate (better two bytes for safety)
    // lda #0
    // ldx InputLength
    // sta PARSER_INPUT_PTR,x
    // inx
    // sta PARSER_INPUT_PTR,x
    // // Disable cursor
    //   // Load PNT (low) into LDA, add PNTR, store to ZP_INDIRECT_ADDR (low)
    // lda $00D1          // Load PNT low byte
    // clc
    // adc $00D3          // Add PNTR (cursor column)
    // sta $00B2          // Store result to ZP_INDIRECT_ADDR low byte
    //   // Load PNT (high), add carry if needed, store to ZP_INDIRECT_ADDR (high)
    // lda $00D2          // Load PNT high byte
    // adc #$00           // Add carry from previous addition
    // sta $00B3          // Store result to ZP_INDIRECT_ADDR high byte
    
    // ldy #$00
    // lda ($b2),y
    // and #$7F          // Clear bit 7 to disable cursor
    // sta ($b2),y
    
    // // New line
    // lda #KEY_RETURN
    // parse and execute
    jsr parse_input
    
    // Clear input buffer and reset cursor
    lda #$00
    sta InputLength
    // sta PARSER_INPUT_PTR
    // sta PARSER_INPUT_PTR+1
    sta CursorPos

    rts

// ============================================================================
// Handle Delete Key
// Removes character before cursor and shifts buffer left
// ============================================================================
// HandleDelete:
// jsr CHROUT
// rts
//     // Check if cursor position is at start
//     lda CursorPos
//     bne !canDelete+
//     rts                 // At start, nothing to delete
// !canDelete:
//     // Delete character before cursor
//     dec CursorPos
    
//     // Shift characters left
//     ldx CursorPos
// DeleteShiftLoop:
//     cpx InputLength
//     bcs DeleteShiftDone
//     lda PARSER_INPUT_PTR+1,x
//     sta PARSER_INPUT_PTR,x
//     inx
//     jmp DeleteShiftLoop
    
// DeleteShiftDone:
//     dec InputLength
    
//     // Move cursor back visually
//     // lda #KEY_CURSOR_LEFT
//     // jsr CHROUT
    
//     // Redraw from current cursor position to end
//     ldx CursorPos
// RedrawDelete:
//     cpx InputLength
//     bcs RedrawDeleteClear
//     lda PARSER_INPUT_PTR,x
//     jsr CHROUT
//     inx
//     jmp RedrawDelete
    
// RedrawDeleteClear:
//     // Print space to clear the deleted character
//     lda #KEY_SPACE
//     jsr CHROUT
    
//     // Move cursor back to correct position
//     lda InputLength
//     sec
//     sbc CursorPos
//     beq DoneDelete
//     tax
// MoveBackDelete:
//     lda #KEY_CURSOR_LEFT
//     jsr CHROUT
//     dex
//     bne MoveBackDelete
    
// DoneDelete:
//     rts

// ============================================================================
// Handle Cursor Left
// ============================================================================
// HandleCursorLeft:
//     lda CursorPos
//     beq !done+          // At start, can't go left
//     dec CursorPos
//     lda #KEY_CURSOR_LEFT
//     jsr CHROUT
// !done:
//     rts

// ============================================================================
// Handle Cursor Right
// ============================================================================
// HandleCursorRight:
//     lda CursorPos
//     cmp InputLength
//     bcs !done+          // At or beyond end of input, can't go right
//     inc CursorPos
//     lda #KEY_CURSOR_RIGHT
//     jsr CHROUT
// !done:
//     rts
