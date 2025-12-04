// Test program for floppy.asm PrintDirectory routine
#import "floppy.asm"

*= $0801 "Basic Upstart"
    BasicUpstart(start)    // 10 sys$0810
* = $0810
start:
    // jsr print_directory
    jsr load_file
    // jsr save_file
    rts
