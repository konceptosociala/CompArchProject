; HEADER
IDEAL
MODEL small
STACK 64

; CONSTANTS
BufSize         EQU     255             ; Maximum string size (<=255)
ASCNull         EQU     0               ; ASCII null
ASCcr           EQU     13              ; ASCII carriage return
ASClf           EQU     10              ; ASCII line feed 

; STRUCTURES
STRUC Data
 index          db 0
 occurances     db 0
ENDS Data

STRUC StrBuffer
 maxlen         db BufSize              ; Maximum buffer length
 strlen         db 0                    ; String length
 chars          db BufSize DUP (0)      ; Buffer for StrRead
ENDS strBuffer

; DATA
DATASEG
sub_string  StrBuffer <>
tmp_string  StrBuffer <>

; CODE
CODESEG
    PROC    MAIN
        start:
            mov ax, @data
            mov ds, ax

            ; Read substring
            mov di, offset sub_string
            call ReadString
            call StrLength

        ; process_strings:
        ;     ; Read strings
        ;     mov si, offset tmp_string
        ;     call ProcessString
        ;     ; Check if EOF
        ;     cmp byte ptr ds:[si+1], ASCNull
        ;     jne process_strings
    
        exit:
            mov ah, 4ch
            int 21h

    ENDP    MAIN

    PROC    ProcessString
            call ReadString

            ret
    ENDP    ProcessString

    ; Read string until space
    PROC    ReadString
        push di
        add di, 2
        read_next:
            mov ah, 3Fh               ; read from input
            mov bx, 0h                ; stdin handle
            mov cx, 1                 ; 1 byte to read
            mov dx, di                ; read to ds:dx 
            int 21h                   ;  ax = number of bytes read
            inc di                    ; next index

            cmp byte ptr ds:[di-1], ' '        ; check if space
            je set
            cmp byte ptr ds:[di-1], ASCcr      ; check if space
            je set
            cmp byte ptr ds:[di-1], ASCNull     ; check if EOF
            je set
            cmp byte ptr ds:[di-1], ASClf       ; check if space
            jne read_next

        set:
            mov [di-1], ASCNull
            pop di
            ret
    ENDP    ReadString

    ;---------------------------------------------------------------
    ; StrLength     Count non-null characters in a string
    ;---------------------------------------------------------------
    ; Input:
    ;       di = address of string (s)
    ; Output:
    ;       cx = number of non-null characters in s
    ; Registers:
    ;       cx
    ;---------------------------------------------------------------
    PROC    StrLength
            push ax
            push di

            mov cx, 0
            add di, 2
        count:
            inc di      
            inc cx              
            cmp byte ptr ds:[di-1], ASCNull
            jne count

            dec cx
            pop di 
            pop ax
            ret
    ENDP    StrLength

    ;---------------------------------------------------------------
    ; StrCompare    Compare two strings
    ;---------------------------------------------------------------
    ; Input:
    ;       si = address of string 1 (s1)
    ;       di = address of string 2 (s2) 
    ; Output:
    ;       flags set for conditional jump using jb, jbe,
    ;        je, ja, or jae.
    ; Registers:
    ;       none
    ;---------------------------------------------------------------
    PROC    StrCompare
            push    ax              ; Save modified registers
            push    di
            push    si
            cld                     ; Auto-increment si
    @@10:
            lodsb                   ; al <- [si], si <- si + 1
            scasb                   ; Compare al and [di]; di <- di + 1
            jne     @@20            ; Exit if non-equal chars found
            or      al, al          ; Is al=0? (i.e. at end of s1)
            jne     @@10            ; If no jump, else exit
    @@20:
            pop     si              ; Restore registers
            pop     di
            pop     ax
            ret                     ; Return flags to caller
    ENDP    StrCompare

    ;---------------------------------------------------------------
    ; StrPos        Search for position of a substring in a string
    ;---------------------------------------------------------------
    ; Input:
    ;       si = address of substring to find
    ;       di = address of target string to scan
    ; Output:
    ;       if zf = 1 then dx = index of substring
    ;       if zf = 0 then substring was not found
    ;       Note: dx is meaningless if zf = 0
    ; Registers:
    ;       dx
    ;---------------------------------------------------------------
    PROC    StrPos
            push    ax              ; Save modified registers
            push    bx
            push    cx
            push    di

            call    StrLength       ; Find length of target string
            mov     ax, cx          ; Save length(s2) in ax
            xchg    si, di          ; Swap si and di
            call    StrLength       ; Find length of substring
            mov     bx, cx          ; Save length(s1) in bx
            xchg    si, di          ; Restore si and di
            sub     ax, bx          ; ax = last possible index
            jb      @@20            ; Exit if len target < len substring
            mov     dx, 0ffffh      ; Initialize dx to -1
    @@10:
            inc     dx              ; For i = 0 TO last possible index
            mov     cl, [byte bx + di]      ; Save char at s[bx] in cl
            mov     [byte bx + di], ASCNull ; Replace char with null
            call    StrCompare              ; Compare si to altered di
            mov     [byte bx + di], cl      ; Restore replaced char
            je      @@20            ; Jump if match found, dx=index, zf=1
            inc     di              ; Else advance target string index
            cmp     dx, ax          ; When equal, all positions checked
            jne     @@10            ; Continue search unless not found

            xor     cx, cx          ; Substring not found.  Reset zf = 0
            inc     cx              ;  to indicate no match
    @@20:
            pop     di              ; Restore registers
            pop     cx
            pop     bx
            pop     ax
            ret                     ; Return to caller
    ENDP    StrPos


END START
