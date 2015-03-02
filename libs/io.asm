%ifndef IO_ASM
%define IO_ASM

%include "./string.asm"

segment .text

raw_rw:

    ; void __cdecl raw_rw(int syscall, int fd, const void *buf, size_t count)

    ;---------------------------------------;
    ; README
    ;
    ; This routine has 2 functionalities, which is input from STDIN
    ; and also can output string to the STDOUT.
    ;
    ; Normally you don't require to use this routine, it's just for
    ; internal purpose.
    ;
    ; - EXAMPLE -
    ;
    ; Input :
    ; syscall   = can be 3 (read) and 4 (write)
    ; fd        = file descriptor, can be 0 (STDIN) or 1 (STDOUT)
    ; buf       = (buffer which size is 20 bytes)
    ; count     = 20
    ;
    ; Usage :
    ;   push    dword 20
    ;   push    buf
    ;   push    dword (can be 1 or 0)
    ;   push    dword (can be 3 or 4)
    ;   call    raw_rw
    ;   add     esp, 16     ; clear stack for pushed perimeters
    ;
    ; Output :
    ; buf = <user input : string>
    ;
    ;----------------------------------------;

    ; setup stack frame
    push    ebp
    mov     ebp, esp
    pusha                           ; push all registers into stack

    ; call read function from kernel, with 4 perimeter
    mov     eax, dword [ebp + (8 + 0)]  ; syscall code (man [code] for more info)
    mov     ebx, dword [ebp + (8 + 4)]  ; int fd
    mov     ecx, dword [ebp + (8 + 8)]  ; void *buf
    mov     edx, dword [ebp + (8 + 12)] ; size_t count
    int     80h                         ; invoke syscall

    ; clear stack for this routine
    popa
    pop     ebp
    ret

str_stdin:

    ; void __cdecl str_stdin(void *buf, int count)

    ;---------------------------------------;
    ; README
    ;
    ; This routine take string user input from user.
    ; Require 2 perimeters, first is buf which is empty buffer string, and
    ; count which is size of buffer
    ;
    ; - EXAMPLE -
    ;
    ; Input :
    ; buf       = (buffer which size is 20 bytes)
    ; count     = 20
    ;
    ; Usage :
    ;   push    dword 20
    ;   push    buf
    ;   call    str_stdin
    ;   add     esp, 8     ; clear stack for pushed perimeters
    ;
    ; Output :
    ; buf = <user input : string>
    ;----------------------------------------;

    ; setup stack frame
    push    ebp
    mov     ebp, esp

    ; call raw_rw with 4 important perimeter
    ; first perimeter is important, cuz its give hint whether we want to read or write

    push    dword [ebp + (8 + 4)]   ; count of buffer
    push    dword [ebp + (8 + 0)]   ; buffer pointer
    push    dword 0                 ; stdin file descriptors
    push    dword 3                 ; read syscall code
    call    raw_rw

    add     esp, 16                 ; clear stack

    ; below is to find 0xa (line seperator value), change it to null terminator

    ; setup ebx registers
    push    ebx                     ; temporary store, use for storing buffer pointer
    push    ecx                     ; store index
    mov     ebx, [ebp + (8 + 0)]    ; copy buf pointer
    xor     ecx, ecx                ; ecx = 0, for counting from 0

    .find_enter:

    ; if ecx (index) already reached max count buffer, then
    cmp     ecx, [ebp + (8 + 4)]
    je      .find_exit

    ; if found 0xA, then stop loop
    cmp     byte [ebx + ecx], 10
    je      .find_exit

    ; if not found 0xA in current byte, then loop and find again
    inc     ecx
    jmp     .find_enter

    .find_exit:

    mov     byte [ebx + ecx], 0     ; replace 0xA with 0x0 (null terminator)

    ; return back value to registers
    pop     ecx
    pop     ebx

    ; clear stack for this routine
    leave
    ret

str_stdout:

    ; void __cdecl str_stdout(void *buf)

    ;---------------------------------------;
    ; README
    ;
    ; Take string buffer from buf pointer, and print it out on STDOUT
    ;
    ; - EXAMPLE -
    ;
    ; Input :
    ; buf       = "Hello, World"
    ;
    ; Usage :
    ;   push    buf
    ;   call    str_stdout
    ;   add     esp, 4     ; clear stack for pushed perimeters
    ;
    ; Output :
    ; None
    ;----------------------------------------;

    ; setup stack frame
    push    ebp
    mov     ebp, esp

    push    eax                     ; store eax for a while

    ; get length of the buffer
    push    dword [ebp + (8 + 0)]
    call    strlen
    add     esp, 4                  ; clear stack

    ; call raw_rw with 4 perimeter (c-style perimeter)

    push    eax                     ; length of buffer
    push    dword [ebp + (8 + 0)]   ; buffer pointer
    push    dword 1                 ; stdout file descriptors
    push    dword 4                 ; write syscall code
    call    raw_rw

    add     esp, 16                 ; clear stack perimeter

    pop     eax                     ; return back eax value

    ; clear stack for this routine
    leave
    ret

long_stdin:

    ; int __cdecl long_stdin()

    ;---------------------------------------;
    ; README
    ;
    ; Take integer input from user, and return it on EAX
    ;
    ; - EXAMPLE -
    ;
    ; Input :
    ; None
    ;
    ; Usage :
    ;   call    long_stdin
    ;
    ; Output :
    ; eax = <user input : integer>
    ;----------------------------------------;

    ; setup stack frame
    push    ebp
    mov     ebp, esp

    push    ecx         ; store ecx for a while

    ; allocate 30 bytes of stack
    sub     esp, 30
    mov     ecx, esp    ; copy current stack pointer into ecx

    ; this will get input from user through str_stdin routine
    push    dword 30                ; length of buffer (for preventing buffer overflow)
    push    ecx                     ; pointer of buffer
    call    str_stdin
    add     esp, 8                  ; clear stack

    ; convert input string from user into integer
    push    dword 10                ; string base number
    push    ecx                     ; destination buffer
    call    strtol                  ; result will be put inside eax
    add     esp, 8                  ; clear stack

    pop     ecx                     ; return back ecx value from the stack

    ; clean stack frame
    leave
    ret

long_stdout:

    ; void __cdecl long_stdout(int num)

    ;---------------------------------------;
    ; README
    ;
    ; Take number from num perimeter, and send into STDOUT
    ;
    ; - EXAMPLE -
    ;
    ; Input :
    ; num   = 99
    ;
    ; Usage :
    ;   push    dword 99
    ;   call    long_stdout
    ;   add     esp, 4     ; clear stack for pushed perimeters
    ;
    ; Output :
    ; None
    ;----------------------------------------;

    ; setup stack frame + store some registers into stack for later use
    push    ebp
    mov     ebp, esp

    ; store eax and ecx into registers for later use
    push    eax
    push    ecx

    ; allocate 20 bytes of stack (to be use in string conversion)
    sub     esp, 20                 ; 20 buf is enough
    mov     ecx, esp                ; move stack buf pointer into ecx

    ; this will convert integer into string by calling ltostr routine
    push    dword 10                       ; base of integer (normal is base 10)
    push    ecx                            ; destination buffer
    push    dword [ebp + (8 + 0)]          ; value of integer perimeter
    call    ltostr
    add     esp, 12                        ; clear stack

    push    ecx
    call    str_stdout
    add     esp, 4                  ; clear stack

    ; clean previous 20 allocated bytes from stack
    add     esp, 20

    ; return back eax & ecx value
    pop     ecx
    pop     eax

    ; clean stack frame
    leave
    ret

%endif
