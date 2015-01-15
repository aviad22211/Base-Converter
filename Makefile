ASSEMBLER 	= nasm
MACHINE		= elf32
DEBUGFORMAT	= dwarf
LINKER 		= gcc
LINKERFLAGS	= -m32
SRCFILE		= base.asm
OBJECTFILE	= base.o
BINARY		= base

.PHONY: all debug clean

all:
	@${ASSEMBLER} -f ${MACHINE} ${SRCFILE} -i './libs/'
	@${LINKER} ${OBJECTFILE} -o ${BINARY} ${LINKERFLAGS}
	@rm -rf ${OBJECTFILE}

debug:
	@${ASSEMBLER} -f ${MACHINE} -F ${DEBUGFORMAT} ${SRCFILE} -i './libs/'
	@${LINKER} ${OBJECTFILE} -o ${BINARY} ${LINKERFLAGS} -ggdb
	@rm -rf ${OBJECTFILE}

clean:
	@rm -rf ${OBJECTFILE} ${BINARY}