#import "constants.asm"
#import "floppy.asm"

// Entry point: expects input command code in A (see ReadInput)

    .const CHAR_8 = $38
    .const CHAR_9 = $39
    .const CHAR_1 = $31
    .const CHAR_0 = $30
    .const CHAR_4 = $34
    .const CHAR_D = $44
    .const CHAR_I = $49
    .const CHAR_R = $52
    .const CHAR_COLON = $3A

    InputDispatch:
        ldx #0
        lda InputBuffer,x
        cmp #CHAR_8
        beq HandleDeviceSwitch
        cmp #CHAR_9
        beq HandleDeviceSwitch
        cmp #CHAR_1
        bne CheckDir
        inx
        lda InputBuffer,x
        cmp #CHAR_0
        beq HandleDeviceSwitch
        cmp #CHAR_1
        beq HandleDeviceSwitch
        cmp #CHAR_4
        beq HandleDeviceSwitch
        jmp CheckDir

    CheckDir:
        ldx #0
        lda InputBuffer,x
        cmp #CHAR_D
        bne CheckPrefixedDir
        inx
        lda InputBuffer,x
        cmp #CHAR_I
        bne CheckPrefixedDir
        inx
        lda InputBuffer,x
        cmp #CHAR_R
        bne CheckPrefixedDir
        jsr HandleDir
        rts

    CheckPrefixedDir:
        ldx #1
        lda InputBuffer,x
        cmp #CHAR_COLON
        bne HandleUnknown
        inx
        lda InputBuffer,x
        cmp #CHAR_D
        bne HandleUnknown
        inx
        lda InputBuffer,x
        cmp #CHAR_I
        bne HandleUnknown
        inx
        lda InputBuffer,x
        cmp #CHAR_R
        bne HandleUnknown
        jsr HandlePrefixedDir
        rts

    HandleDeviceSwitch:
        sta $d021
        rts

    HandleDir:
        jsr PrintDirectory
        rts

    HandlePrefixedDir:
        rts

    HandleUnknown:
        rts
    ReadInput:
        rts

    ReadNextChar:
        rts

