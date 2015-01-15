%ifndef STRING_INC
%define STRING_INC

%include "./math.inc"

segment .text

strlen:

    ; int strlen(void *buf)

    ;---------------------------------------;
    ; README
    ;
    ; This one is simple, put your string pointer into buf perimeter,
    ; you will get your result inside eax register.
    ;
    ; C PSEUDOCODE
    ;
    ; int strlen(char *buf)
    ; {
    ;   int len = 0;
    ;   while(buf[len] != 0 && ++len);   
    ;   return len;
    ; }
    ;---------------------------------------;

    push    ebp
    mov     ebp, [esp + 8]

    xor     eax, eax        ; set eax to 0, use to counting length

    .strlen_loop:

    ; end this routine if we had found null terminator (end of a string)
    cmp     [ebp+eax], byte 0
    je      .strlen_exit

    ; if still not found null terminator, continues looping
    inc     eax
    jmp     .strlen_loop

    .strlen_exit:

    pop     ebp
    ret

strtol:

    ; int strtol(void *buf, int strBase)

    ;---------------------------------------;
    ; README
    ;
    ; This routine takes string from perimeter, take also number base
    ; of the string number, then convert it into integer value.
    ;
    ; To make this clear, let say, I want following number
    ;   "1000" in string, and it's in the base 10
    ;
    ; So, at buf perimeter, put your "1000" pointer inside it.
    ; For strBase, we know that 1000 is clearly in base 10 number
    ; (it can also be binary, octal, base 5, etc), but we indicated it 
    ; as base 10, so at strBase perimeter, set it to be 10.
    ;
    ; Hint on how this internally works, it's start working with the right-most number
    ; into left-most number. If you're so curious on how this thing work, then have
    ; a look in below assembly.
    ;----------------------------------------;

    ; setup stack frame
    push    ebp
    mov     ebp, esp
    sub     esp, 4
    pusha

    mov     esi, [ebp + (8+4)]               ; hold address for input string

    ; get length of buf string buffer
    push    esi
    call    strlen                           ; length will be return to eax

    add     esp, 4                           ; use to store result value at the last of routine

    ; set up registers to be use in counting
    xor     ecx, ecx                         ; ecx = 0, gonna hold value
    dec     eax                              ; decrease by 1 (to use inside loop)
    xor     ebx, ebx                         ; ebx = 0, counting for pow

    .strtol_loop:

    ; if eax index reach -1 (which is not valid string index), then end loop
    cmp     eax, 0
    jl      .strtol_exit

    ; calculation

    xor     edx, edx                         ; edx = 0
    mov     dl, byte [esi+eax]               ; copy character inside string into d lower
    mov     edi, edx
    sub     edi, 48                          ; get integer from ascii number

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
    push    dword [ebp + (8+0)]
    push    ebx
    ;push    eax
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
    mov     esp, ebp
    pop     ebp
    ret

ltostr:

    ; void ltostr(int num, void *buf, int strBase)

    ; setup stack frame
    push    ebp
    mov     ebp, esp
    pusha                          ; push all registers into stack

    ; set-up registers & move perimeter values into registers
    xor     ecx, ecx               ; ecx = 0, gonna hold buf index
    mov     eax, [ebp + (8+8)]     ; perimeter 1 (int num)
    mov     ebx, [ebp + (8+4)]     ; perimeter 2 (void *buf)
    mov     edi, [ebp + (8+0)]     ; perimeter 3 (int strBase)

    .ltostr_loop:

    ; lets make 'do while' style inside asm :D 

    ; divide edx:eax by edi value, edx will hold remainder
    xor     edx, edx               ; edx = 0
    div     edi                    ; divide num by edi

    ; get remainder value, and add 48 to make it suitable with ascii format
    add     edx, 48
    mov     [ebx+ecx], dl          ; move first 1 byte of edx into buf str buffer
    inc     ecx                    ; increment index (low to high) N-1
 
    ; check if eax (which is divided "div" value) reach zero
    ; if equal zero (which already reach end of number), then stop looping
    ; otherwise go back and make calculation again
    cmp     eax, 0
    jne     .ltostr_loop

    ; this is important, null terminator is important
    mov     [ebx+ecx], byte 0

    ; calculation done, need to do some string reverse to get nice looking string
    push    ebx
    call    strrev
    add     esp, 4                  ; clear stack

    ; clear stack frame
    popa
    pop     ebp
    ret

strrev:

    ; void strrev(void *buf)

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
    mov     esp, ebp
    pop     ebp
    ret

%endif