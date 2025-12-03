// Test program for floppy.asm PrintDirectory routine
#import "floppy.asm"

* = $0801
// BASIC header for SYS2064
.byte $0c, $08, $0a, $00, $9e, $32, $30, $36, $34, $00, $00, $00

* = $0810
Start:
    jsr PrintDirectory
    rts
