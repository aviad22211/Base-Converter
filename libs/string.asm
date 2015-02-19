%ifndef STRING_ASM
%define STRING_ASM

%include "./math.asm"

segment .text

strlen:

    ; __attribute__((cdecl)) size_t strlen(void *buf)

    ;---------------------------------------;
    ; README
    ;
    ; This routine take string from perimeter, and count the
    ; bytes/characters until reach zero (null terminated character).
    ;
    ; - EXAMPLE -
    ;
    ; Input :
    ; buf       = "Micro$oft"
    ;
    ; Usage :
    ;   push    buf
    ;   call    strtol
    ;   add     esp, 4     ; clear stack for pushed perimeter
    ;
    ; Output :
    ; eax = 9
    ;
    ; Note :
    ; - Behaviour is undefined if not string is inserted in perimeter.
    ;----------------------------------------;

    push    ebp
    mov     ebp, [esp + 8]

    xor     eax, eax        ; set eax to 0, use to counting length

    .strlen_loop:

    ; end this routine if we had found null terminator (end of a string)
    cmp     [ebp + eax], byte 0
    je      .strlen_exit

    ; if still not found null terminator, continues looping
    inc     eax
    jmp     .strlen_loop

    .strlen_exit:

    pop     ebp
    ret

strtol:

    ; __attribute__((cdecl)) int strtol(void *buf, int strBase)

    ;---------------------------------------;
    ; README
    ;
    ; This routine take string from perimeter, also take number base
    ; of the string number, then convert it into integer value.
    ;
    ; - EXAMPLE -
    ;
    ; Input :
    ; buf       = "1111"
    ; strBase   = 2
    ;
    ; Usage :
    ;   push    dword 2
    ;   push    buf
    ;   call    strtol
    ;   add     esp, 8     ; clear stack for pushed perimeters
    ;
    ; Output :
    ; eax = 15 (signed number)
    ;
    ;----------------------------------------;

    ; setup stack frame
    push    ebp
    mov     ebp, esp
    sub     esp, 4
    pusha

    mov     esi, [ebp + (8+0)]               ; hold address for input string

    ; get length of buf string buffer
    push    esi
    call    strlen                           ; length will be return to eax

    add     esp, 4                           ; use to store result value at the last of routine

    ; set up registers to be use in counting
    xor     ecx, ecx                         ; ecx = 0, gonna hold value
    dec     eax                              ; decrease by 1 (to use inside loop)
    xor     ebx, ebx                         ; ebx = 0, counting for pow

    .strtol_loop:

    ; check if '-' (negative) is found
    cmp     byte [esi+eax], 45              ; ascii character for '-'
    jne     .strtol_con_no_neg

    neg     ecx                             ; make 2's complement operation on unsigned number
    jmp     .strtol_exit                    ; finish off after number have converted

    .strtol_con_no_neg:

    ; if eax index reach -1 (which is not valid string index), then end loop
    cmp     eax, 0
    jl      .strtol_exit

    ; calculation

    xor     edx, edx                         ; edx = 0
    mov     dl, byte [esi+eax]               ; copy character inside string into d lower
    mov     edi, edx

    ; check if '+' (plus sign) is found, if yes then exit
    cmp     edi, 43              ; ascii character for '+'
    je      .strtol_exit

    ; checking for letter

    cmp     edi, 57
    jle    .strtol_normal_ascii

    ; check if char is A-Z
    cmp     edi, 90
    jle     .strtol_big_char

    sub     edi, 61                          ; get low letter number from character (start with base 37)
    jmp     .strtol_cont_calc

    .strtol_big_char:

    sub     edi, 55                          ; get big letter number from character (start with base 11)
    jmp     .strtol_cont_calc

    .strtol_normal_ascii:

    sub     edi, 48                          ; get integer from ascii number

    .strtol_cont_calc:

    ; if number is zero (multiply any number with 0 will get 0 anyway), then skip this number
    ; this improve performance alot when source base is in base 2 (binary)
    cmp     edi, 0
    jne      .strtol_continue

    ; if zero, then do next number, we will skip number 0
    dec     eax
    inc     ebx
    jmp     .strtol_loop

    .strtol_continue:

    push    eax

    ; get (ebp+8 power of) of N-1 string index
    push    ebx
    push    dword [ebp + (8+4)]
    call    pow

    add     esp, 8                           ; clear stack
    mul     edi                              ; edx:eax = eax * edi

    ; add into the total value + new value
    add     ecx, eax

    pop     eax                              ; return back eax value
    dec     eax                              ; eax = counting, for next loop, dec by 1
    inc     ebx                              ; increase scale of index for power of
    jmp     .strtol_loop

    .strtol_exit:

    ; move ecx into eax (eax is standard return value register)
    mov     [ebp-4], ecx
    popa
    mov     eax, [ebp-4]
    add     esp, 4

    ; cleaning up stack frame
    leave
    ret

ltostr:

    ; __attribute__((cdecl)) void ltostr(int num, void *buf, int strBase)

    ;---------------------------------------;
    ; README
    ;
    ; This routine take 3 perimeters, first is num, this must be in
    ; base10 signed number, second is destination buffer, and third is destination
    ; buffer number base to present.
    ;
    ; - EXAMPLE -
    ;
    ; Input :
    ; num       = 300
    ; buf       = (buffer size 20)
    ; strBase   = 2
    ;
    ; Usage :
    ;   push    dword 2
    ;   push    buf
    ;   push    dword 300
    ;   call    ltostr
    ;   add     esp, 12     ; clear stack for pushed perimeters
    ;
    ; Output :
    ; buf = "100101100"
    ;
    ;----------------------------------------;

    ; setup stack frame
    push    ebp
    mov     ebp, esp
    pusha                          ; push all registers into stack

    ; set-up registers & move perimeter values into registers
    xor     ecx, ecx               ; ecx = 0, gonna hold buf index
    mov     eax, [ebp + (8+0)]     ; perimeter 1 (int num)
    mov     ebx, [ebp + (8+4)]     ; perimeter 2 (void *buf)
    mov     edi, [ebp + (8+8)]     ; perimeter 3 (int strBase)
    xor     esi, esi               ; signed number +ve

    cmp     edi, 10
    jne     .ltostr_loop

    test    eax, 0x80000000        ; check if right-most side bit is set (which is -ve number in signed value)
    jz     .ltostr_loop

    inc     esi
    neg     eax

    .ltostr_loop:

    ; lets make 'do while' style inside asm :D

    ; divide edx:eax by edi value, edx will hold remainder
    xor     edx, edx               ; edx = 0
    div     edi                    ; divide num by edi

    ; check if edx is below than 10
    cmp     edx, 10
    jl      .ltostr_below_ten

    cmp     edx, 36
    jl      .ltostr_below_thirty

    add     edx, 61                ; if remainder is more than 36, then make it to be character a-z
    jmp     .ltostr_done_change_ascii

    .ltostr_below_thirty:

    add     edx, 55                ; if remainder is 10-35, then make it to be character A-Z
    jmp     .ltostr_done_change_ascii

    .ltostr_below_ten:

    ; get remainder value, and add 48 to make it suitable with ascii format
    add     edx, 48

    .ltostr_done_change_ascii:

    mov     [ebx+ecx], dl          ; move first 1 byte of edx into buf str buffer
    inc     ecx                    ; increment index (low to high) N-1

    ; check if eax (which is divided "div" value) reach zero
    ; if equal zero (which already reach end of number), then stop looping
    ; otherwise go back and make calculation again
    cmp     eax, 0
    jne     .ltostr_loop

    test    esi, 1
    jz      .ltostr_null

    mov     [ebx+ecx], byte 40     ; add junk data (=.=)
    inc     ecx

    .ltostr_null:

    ; this is important, null terminator is important
    mov     [ebx+ecx], byte 0

    ; calculation done, need to do some string reverse to get nice looking string
    push    ebx
    call    strrev
    add     esp, 4                  ; clear stack

    test    esi, 1                  ; check if right-most bit is set (-ve) or not set (+ve)
    jz      .ltostr_exit

    mov     [ebx], byte 45          ; add '-' minus sign at right most string

    .ltostr_exit:

    ; clear stack frame
    popa
    pop     ebp
    ret

strrev:

    ; __attribute__((cdecl)) void strrev(void *buf)

    ;---------------------------------------;
    ; README
    ;
    ; This routine take string buffer from perimeter, and reverse it.
    ;
    ; - EXAMPLE -
    ;
    ; Input :
    ; buf = "123456"
    ;
    ; Usage :
    ; push  buf
    ; call  strrev
    ; add   esp, 4  ; clear previous pushed perimeter
    ;
    ; Output :
    ; buf = "654321"
    ;----------------------------------------;

    ; setup stack frame
    push    ebp
    mov     ebp, esp
    pusha

    mov     edi, [ebp + (8+0)]      ; copy (void *)buf into edi

    ; get length of buffer
    push    edi
    call    strlen
    add     esp, 4                  ; clear stack

    ; setup registers
    dec     eax                     ; count from backward (N-1)
    xor     ebx, ebx                ; ebx = 0, count from frontward

    .strrev_loop:

    ; compare if ebx exceeds eax, if yes, string reverse finished, and stop looping
    cmp     ebx, eax
    jg      .sttrev_exit

    ; swap between 2 bytes
    mov     cl, [edi + eax]
    mov     ch, [edi + ebx]
    mov     [edi + ebx], cl
    mov     [edi + eax], ch

    ; decrement downward, increment frontward, and continues looping
    dec     eax
    inc     ebx
    jmp     .strrev_loop

    .sttrev_exit:

    ; clear stack frame
    popa
    leave
    ret

%endif
