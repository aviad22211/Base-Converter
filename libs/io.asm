%ifndef IO_ASM
%define IO_ASM

%include "./string.asm"

segment .text

raw_rw:

    ; void raw_rw(int syscall, int fd, const void *buf, size_t count)

    ; setup stack frame
    push    ebp
    mov     ebp, esp
    pusha                           ; push all registers into stack

    ; call read function from kernel, with 4 perimeter
    mov     eax, dword [ebp + (8 + 12)] ; syscall code (man [code] for more info)
    mov     ebx, dword [ebp + (8 + 8)]  ; int fd
    mov     ecx, dword [ebp + (8 + 4)]  ; void *buf
    mov     edx, dword [ebp + (8 + 0)]  ; size_t count
    int     80h                         ; invoke syscall

    ; clear stack for this routine
    popa
    pop     ebp
    ret

str_stdin:

    ; void str_stdin(void *buf, int length)

    ; setup stack frame
    push    ebp
    mov     ebp, esp

    ; call raw_rw with 4 important perimeter
    ; first perimeter is important, cuz its give hint whether we want to read or write
    push    dword 3                 ; read syscall code
    push    dword 0                 ; stdin file descriptors
    push    dword [ebp + (8 + 4)]   ; buffer pointer
    push    dword [ebp + (8 + 0)]   ; length of buffer
    call    raw_rw

    add     esp, 16                 ; clear stack

    ; below is to find 0xa (line seperator value), change it to null terminator

    ; setup ebx registers
    push    ebx                     ; temporary store, use for storing buffer pointer
    push    ecx                     ; store index
    mov     ebx, [ebp + (8 + 4)]    ; copy buf pointer
    xor     ecx, ecx                ; ecx = 0, for counting from 0

    .find_enter:

    ; if ecx (index) already reached length buffer, then 
    cmp     ecx, [ebp + (8 + 0)]
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

    ; void str_stdout(void *buf)

    ; setup stack frame
    push    ebp
    mov     ebp, esp

    push    eax                     ; store eax for a while

    ; get length of the buffer
    push    dword [ebp + (8 + 0)]
    call    strlen
    add     esp, 4                  ; clear stack

    ; call raw_rw with 4 perimeter (c-style perimeter)
    push    dword 4                 ; write syscall code
    push    dword 1                 ; stdout file descriptors
    push    dword [ebp + (8 + 0)]   ; buffer pointer
    push    eax                     ; length of buffer
    call    raw_rw

    add     esp, 16                 ; clear stack perimeter

    pop     eax                     ; return back eax value

    ; clear stack for this routine
    leave
    ret

long_stdin:

    ; int long_stdin()

    ; setup stack frame
    push    ebp
    mov     ebp, esp

    push    ecx         ; store ecx for a while

    ; allocate 30 bytes of stack
    sub     esp, 30
    mov     ecx, esp    ; copy current stack pointer into ecx

    ; this will get input from user through str_stdin routine
    push    ecx                     ; pointer of buffer
    push    dword 30                ; length of buffer (for preventing buffer overflow)
    call    str_stdin
    add     esp, 8                  ; clear stack

    ; convert input string from user into integer
    push    ecx
    push    dword 10
    call    strtol                  ; result will be put inside eax
    add     esp, 8                  ; clear stack

    pop     ecx                     ; return back ecx value from the stack

    ; clean stack frame
    leave
    ret

long_stdout:

    ; void long_stdout(int num)

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
    push    dword [ebp + (8 + 0)]          ; value of integer perimeter
    push    ecx                            ; destination buffer
    push    dword 10                       ; base of integer (normal is base 10)
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