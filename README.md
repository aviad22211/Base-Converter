# Base-Converter
Simple base converter written using x86 NASM Assembly Language

# Requirement(s)
- Linux
- NASM Assembler
- GCC (as linker)

To assemble this program, simply run `make`. If you want output executable with debugging info, type `make debug`.
Please note that this program will not compile under platform other than <b>Linux</b>. Because this program is using Linux API to input/output data from user.

Also this program isn't fast enough like one that produced by high-level compilers. This was written as practice for me while learning assembly language.
So in time, I will update this program to optimize it while I'm learning how compiler optimized high-level language.

# Feature(s)
- Can support number bases up to Base 36.

# Limitation(s)
- Can't support integer input more than 32 bit.

# Credit(s)
<a href='https://github.com/nikAizuddin'>Nik Mohamad Aizuddin</a> - For helping me with input stdin bug.
