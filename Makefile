# Makefile for MujBASIC project

KICKASS_JAR = /home/honza/projects/c64/pc-tools/kickass/KickAss.jar
ASM_SRC = mujbasic.asm
BIN_OUT = mujbasic.bin

.PHONY: all build run run-std clean

all: build

build:
	rm -f $(BIN_OUT)
	java -jar $(KICKASS_JAR) $(ASM_SRC)

run: build
	x64sc -basic $(BIN_OUT) -reu -reusize 128 -8 data/001a.d64

run-std:
	x64sc -basic /usr/local/share/vice/C64/basic-901226-01.bin -reu -reusize 128 -8 data/001a.d64 $(ARG)
# 	x64sc -basic /usr/local/share/vice/C64/basic-901226-01.bin -reu -reusize 128 -8 data/empty.d64 $(ARG)

clean:
	rm -f $(BIN_OUT) *.dbg *.sym *.vs *.prg

