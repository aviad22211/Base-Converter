# Base-Converter
Simple base converter written using x86 NASM Assembly Language

# Requirement(s)
- Linux
- NASM Assembler
- GCC (as linker)

To assemble this program, simply run `make`. If you want output executable with debugging info, type `make debug`.
Please note that this program will not compile under platform other than <b>Linux</b>. Because this program is using Linux API to input/output data from user.

Also this program isn't fast enough like one that produced by high-level compilers. This was written as practice for me while learning assembly language.
So in time, I will update this program to optimize it while I'm learning how compiler translated/optimized high-level language.

-- updates --
https://godbolt.org/ - good website that can enable us to see compiler assembly output with ease.

# Feature(s)
- Can support number bases from Base 2 until Base 62.
- Support signed number. (2's complement)

# Limitation(s)
- Can't support integer input more than 32 bit.
- Floating number isn't in support yet.

# Credit(s)
<a href='https://github.com/nikAizuddin'>Nik Mohamad Aizuddin</a> - For helping me with input stdin bug.
