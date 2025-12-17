# Makefile for Hondani Shell project

KICKASS_JAR = /home/honza/projects/c64/pc-tools/kickass/KickAss.jar
ASM_SRC = hdnsh.asm
BIN_OUT = hdnsh.bin

# Common VICE emulator options
REU_OPTS = -reu -reusize 128
DISK_OPTS = -8 data/001a.d64 -9 data/002b.d64
FS11_OPTS = -iecdevice11 -device11 1 -fs11 data/
#FS9_OPTS = -iecdevice9 -device9 1 -fs9 data/
VICE_OPTS = $(REU_OPTS) $(DISK_OPTS) $(FS11_OPTS)
# $(FS11_OPTS)

.PHONY: all build run run-std clean

all: build

build:
	rm -f $(BIN_OUT)
	java -jar $(KICKASS_JAR) $(ASM_SRC)

run: build
	x64sc -basic $(BIN_OUT) $(VICE_OPTS)

run-std:
	x64sc -basic /usr/local/share/vice/C64/basic-901226-01.bin $(VICE_OPTS) $(ARG)
# 	x64sc -basic /usr/local/share/vice/C64/basic-901226-01.bin -reu -reusize 128 -8 data/empty.d64 $(ARG)

clean:
	rm -f $(BIN_OUT) *.dbg *.sym *.vs *.prg

