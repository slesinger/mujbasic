.importonce
#import "constants.asm"
#import "utils.asm"

/*
// floppy.asm - PrintDirectory routine for C64
// Prints the disk directory in standard C64 format

// PrintDirectory: Prints the disk directory to the screen
// Uses KERNAL routines for I/O
// Assumes device 8 (default disk drive)

PrintDirectory:
    // Use logical file 15 (conventional for disk ops), device 8, secondary 15 (directory)
    lda #15            // logical file number
    ldx #8             // device 8 (1541)
    ldy #15            // secondary address 15 => directory
    jsr SetLFSAndOpen  // call helper which will SETLFS/SETNAM/OPEN
        // Debug visual: show we entered directory routine (set border to green)
        lda #6
        sta $d020

        // Check status after OPEN
        jsr $FFB7          // READST -> A = status
        beq dir_ok         // if zero, OK
        // Non-zero status: show low nibble on border and print message
        and #$0F
        sta $d020
        ldx #<err_status_msg
        ldy #>err_status_msg
        jsr print_string
        rts

    dir_ok:

    // Define logical file 15 as input channel and read until EOF
    ldx #15
    jsr $FFC6          // CHKIN

print_dir_loop:
    jsr $FFB7          // READST
    and #64            // test EOF bit
    bne dir_end
    jsr $FFCF          // CHRIN (read char into A)
    jsr $FFD2          // CHROUT (print char)
    jmp print_dir_loop

dir_end:
    jsr $FFCC          // CLRCHN (restore default channels)
        // restore border to default (black)
        lda #0
        sta $d020
    rts

dir_error:
    ldx #<err_msg
    ldy #>err_msg
    jsr print_string
    rts

// Helper: SetLFSAndOpen
// Sets LFS and opens directory for reading
SetLFSAndOpen:
    // Expecting A = logical file number, X = device, Y = secondary
    // save incoming registers so we can retry fallback ordering
    sta save_lfn
    stx save_dev
    sty save_sec

    // --- Attempt 1: SETLFS, SETNAM, OPEN ---
    lda #2
    sta $d020          // border = color 2 (attempt start)

    jsr $FFBA          // SETLFS  (A = lfn, X = device, Y = secondary)
    jsr $FFB7          // READST
    sta save_status
    lda save_status
    beq ok_after_setlfs1
    // print full status for debugging
    ldx #<setlfs_status_prefix
    ldy #>setlfs_status_prefix
    jsr print_string
    jsr show_status
    // SETLFS returned error: show low nibble and print message
    lda save_status
    and #$0F
    sta $d020
    ldx #<setlfs_err_msg
    ldy #>setlfs_err_msg
    jsr print_string

ok_after_setlfs1:
    lda #3
    sta $d020          // border = color 3 (about to SETNAM)

    lda #1
    ldx #<dir_name
    ldy #>dir_name
    jsr $FFBD          // SETNAM (A = length, X/Y = address of name)
    jsr $FFB7
    sta save_status
    lda save_status
    beq ok_after_setnam1
    ldx #<setnam_status_prefix
    ldy #>setnam_status_prefix
    jsr print_string
    jsr show_status
    lda save_status
    and #$0F
    sta $d020
    ldx #<setnam_err_msg
    ldy #>setnam_err_msg
    jsr print_string

ok_after_setnam1:
    lda #4
    sta $d020          // border = color 4 (about to OPEN)
    // restore A/X/Y from saved values for OPEN
    lda save_lfn
    ldx save_dev
    ldy save_sec
    jsr $FFC0          // OPEN
    jsr $FFB7
    sta save_status
    lda save_status
    bne open_failed1
    // OPEN succeeded: set border and return
    lda #1
    sta $d020
    rts
open_failed1:
    ldx #<open_status_prefix
    ldy #>open_status_prefix
    jsr print_string
    jsr show_status

    // OPEN failed — try fallback ordering: SETNAM then SETLFS then OPEN
    and #$0F
    sta $d020
    ldx #<open_err_msg
    ldy #>open_err_msg
    jsr print_string

    // clear channels before retry
    jsr $FFCC

    lda #5
    sta $d020          // border = color 5 (fallback start)

    // SETNAM first
    lda #1
    ldx #<dir_name
    ldy #>dir_name
    jsr $FFBD
    jsr $FFB7
    sta save_status
    lda save_status
    beq ok_after_setnam2
    ldx #<setnam2_status_prefix
    ldy #>setnam2_status_prefix
    jsr print_string
    jsr show_status
    lda save_status
    and #$0F
    sta $d020
    ldx #<setnam_err_msg2
    ldy #>setnam_err_msg2
    jsr print_string

ok_after_setnam2:
    // restore original lfn/device/sec
    lda save_lfn
    ldx save_dev
    ldy save_sec
    jsr $FFBA          // SETLFS
    jsr $FFB7
    sta save_status
    lda save_status
    beq ok_after_setlfs2
    ldx #<setlfs2_status_prefix
    ldy #>setlfs2_status_prefix
    jsr print_string
    jsr show_status
    lda save_status
    and #$0F
    sta $d020
    ldx #<setlfs_err_msg2
    ldy #>setlfs_err_msg2
    jsr print_string

ok_after_setlfs2:
    // OPEN now
    lda save_lfn
    ldx save_dev
    ldy save_sec
    jsr $FFC0
    jsr $FFB7
    sta save_status
    lda save_status
    bne open2_failed
    // OPEN succeeded: set border and return
    lda #1
    sta $d020
    rts
open2_failed:
    ldx #<open2_status_prefix
    ldy #>open2_status_prefix
    jsr print_string
    jsr show_status

    // both attempts failed — show message and return
    and #$0F
    sta $d020
    ldx #<open_all_fail_msg
    ldy #>open_all_fail_msg
    jsr print_string
    rts

opened_ok1:
    lda #1
    sta $d020
    rts

opened_ok2:
    lda #1
    sta $d020
    rts


dir_name: .byte 36    // PETSCII '$' (0x24)

// Helper: print_string
// Print zero-terminated string at (X, Y)
print_string:
    stx ptrlo
    sty ptrhi
    ldy #0
ps_loop:
    lda (ptrlo),y
    beq ps_end
    jsr $FFD2
    iny
    bne ps_loop
ps_end:
    rts

// Print string but ensure output goes to screen first (CLRCHN)
print_to_screen:
    jsr $FFCC   // restore default channels (screen)
    jsr print_string
    rts

// Zero page pointer for print_string
ptrlo: .byte 0
ptrhi: .byte 0

// saved registers for retry logic
save_lfn: .byte 0
save_dev: .byte 0
save_sec: .byte 0



err_msg:
    .text "DIR ERROR"
    .byte 0

err_status_msg:
    .text "DIR OPEN STATUS"
    .byte 0

setlfs_err_msg:
    .text "SETLFS ERR"
    .byte 0

setnam_err_msg:
    .text "SETNAM ERR"
    .byte 0

open_err_msg:
    .text "OPEN ERR, RETRY"
    .byte 0

setnam_err_msg2:
    .text "SETNAM2 ERR"
    .byte 0

setlfs_err_msg2:
    .text "SETLFS2 ERR"
    .byte 0

open_all_fail_msg:
    .text "OPEN ALL FAILED"
    .byte 0

setlfs_status_prefix:
    .text "SETLFS ST="
    .byte 0

setnam_status_prefix:
    .text "SETNAM ST="
    .byte 0

open_status_prefix:
    .text "OPEN ST="
    .byte 0

setnam2_status_prefix:
    .text "SETNAM2 ST="
    .byte 0

setlfs2_status_prefix:
    .text "SETLFS2 ST="
    .byte 0

open2_status_prefix:
    .text "OPEN2 ST="
    .byte 0
*/

// Filename is temporary fixed to "SOUND2" PRG. Its start address is $1800
// Input: TBD
// Output: None, file loaded
// Registers modified: A, X, Y
LoadFile:
    lda #$01  // logical number, can have up to 5 opened at the same time
    ldx #$08  // device number
    ldy #$01  // command, secondary address normally 1 to use PRG address (or .X , .Y LOAD ADDRESS IF SA=0 )
    jsr SETLFS          // call KERNAL set logical file parameters

    lda #$06            // length of filename
    ldx #<SOUND2        // low byte of filename address
    ldy #>SOUND2        // high byte of filename address
    jsr SETNAM          // call KERNAL set file name

    lda #$00      // load (not verify)
    ldx #$00
    ldy #$50           // load to $5000
    jsr LOAD
    bcc LoadFileDone  // if no error, done
    // Error occurred during load
    jsr ShowStatus
    rts
LoadFileDone:
    // Display load start-end address
    // TODO to get start address of the load in non-relocatable mode, first two bytes need to be loaded first with open/read/read/close
    lda #@KEY_SPACE
    jsr CHROUT
    lda #KEY_MINUS
    jsr CHROUT
    lda #@KEY_DOLLAR
    jsr CHROUT
    stx TMP2
    sty TMP2+1      // save end address in TMP2/TMP2+1
    jsr SHOWAD
    lda #KEY_RETURN
    jsr CHROUT
    rts

SaveFile:
    lda #$01  // logical number, can have up to 5 opened at the same time
    ldx #$08  // device number
    ldy #$01  // secondary address, command, use PRG address  (or .X , .Y LOAD ADDRESS IF SA=0 )
    jsr SETLFS          // call KERNAL set logical file parameters

    lda #$06            // length of filename
    ldx #<MEDLIK        // low byte of filename address
    ldy #>MEDLIK        // high byte of filename address
    jsr SETNAM          // call KERNAL set file name

    lda #$00
    sta ZP_INDIRECT_ADDR_2
    lda #$04
    sta ZP_INDIRECT_ADDR_2 + 1  // start address $0400

    lda #ZP_INDIRECT_ADDR_2      // page 0 offset
    ldx #$2b
    ldy #$04           // load up to $042b
    jsr SAVE
jmp *
    rts


// Print status byte in A as two hex digits
// Input: A = status byte
// Registers modified: A, X, Y
ShowStatus:
    sta SAVX      // save status byte
    lda #KEY_E
    jsr CHROUT
    lda #KEY_R
    jsr CHROUT
    lda #KEY_R
    jsr CHROUT
    lda #KEY_SPACE
    jsr CHROUT
    lda #KEY_DOLLAR
    jsr CHROUT
    // print high nibble
    lda SAVX
    lsr
    lsr
    lsr
    lsr                 // A = high nibble
    jsr print_nibble
    // print low nibble
    lda SAVX
    and #$0F
    jsr print_nibble
    lda #KEY_RETURN
    jsr CHROUT
    rts



SOUND2: .text "SOUND2"
MEDLIK: .text "MEDLIK"
// SOUND2: .byte $2a, $00  // *
// SOUND2: .byte $22, $2a, $22, $00  // "*"
// SOUND2: .byte $13, $0f, $15, $0e, $04, $32, $00  // "SOUND2"
