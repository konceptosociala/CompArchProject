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
STRUC ParseData
 index          db 255
 occurances     db 255
ENDS ParseData

STRUC StrBuffer
 maxlen         db BufSize              ; Maximum buffer length
 strlen         db 0                    ; String length
 chars          db BufSize DUP (0)      ; Buffer for StrRead
ENDS StrBuffer

; DATA
DATASEG
sub_string      StrBuffer <>
tmp_string      StrBuffer <>
parse_data      ParseData 100 dup(<>)

; CODE
CODESEG
    PROC    MAIN
        start:
            call InitDataSegment
            call GetSubstring    
        process_strings:
            mov si, offset sub_string
            mov di, offset tmp_string
            ; Read string
            call ClearString
            call ReadString
            call StrLength
            mov [tmp_string.strlen], cl
            ; StrPos
            call StrCompare
            je exit
            mov ax, 66
            ; Check if EOF
            cmp [byte ptr ds:[di+1]], 0
            jne process_strings
        exit:
            mov ah, 4ch
            int 21h

    ENDP    MAIN

    PROC    InitDataSegment
            mov ax, @data
            mov ds, ax 
    ENDP    InitDataSegment

    PROC    GetSubstring
            ; Reserve registers
            push si
            push di
            push cx
            push bx
            ; Get first argument
            mov cl, [es:[80h]]
            xor ch, ch
            mov bx, 81h
            mov di, 82h
            add bx, cx
            mov [byte ptr es:[bx]], 0
            ; Write to substring
            mov bx, 0
            mov si, offset sub_string.chars
        copy_char:
            mov bl, [es:[di]]
            mov [byte ptr ds:[si]], bl
            inc si
            inc di
            cmp [byte ptr es:[di-1]], ASCNull
            jne copy_char
            mov di, offset sub_string
            call StrLength
            mov [sub_string.strlen], cl
            ; Restore registers
            pop bx
            pop cx
            pop di
            pop si  
            ret
    ENDP    GetSubstring

;     PROC    ProcessString
;             ; Reserve registers
;             push ax
;             push bx
;             push cx
;             push dx
;             push di
;             ; Read string
;             call ClearString
;             call ReadString
;             call StrLength
;             mov [tmp_string.strlen], cl
;             ; StrPos
;             call StrPos
;             ; Restore registers               
;             pop di
;             pop dx
;             pop cx
;             pop bx
;             pop ax
;             ret
;     ENDP    ProcessString

    PROC    ClearString
            ; Reserve registers
            push di
            push cx
            ; Clear strlen
            mov [byte ptr ds:[di+1]], 0
            ; StrBuffer.chars
            add di, 2
            ; Counter
            mov cx, 0
        clear_char:
            mov [byte ptr ds:[di]], 0
            inc di
            inc cx
            cmp cx, 255
            jne clear_char
            ; Restore registers
            pop cx
            pop di
            ret
    ENDP    ClearString

    PROC    ReadString
            ; Reserve registers
            push ax
            push bx
            push cx
            push dx
            push di
            ; StrBuffer.chars
            add di, 2
        check_lf:
            mov ah, 3Fh               
            mov bx, 0h                
            mov cx, 1                 
            mov dx, di 
            int 21h                   
            inc di
            cmp [byte ptr ds:[di-1]], ASClf
            jne read_next
        if_lf:
            dec di
            mov [byte ptr ds:[di]], ASCNull
        read_next:
            mov ah, 3Fh               ; read from input
            mov bx, 0h                ; stdin handle
            mov cx, 1                 ; 1 byte to read
            mov dx, di                ; read to ds:dx 
            int 21h                   ;  ax = number of bytes read
            inc di                    ; next index
            cmp [byte ptr ds:[di-1]], ASClf      ; check if lf
            je set
            cmp [byte ptr ds:[di-1]], ASCcr      ; check if cr
            je set
            cmp [byte ptr ds:[di-1]], ASCNull    ; check if EOF
            jne read_next

        set:
            mov [byte ptr ds:[di-1]], ASCNull
            ; Restore registers               
            pop di
            pop dx
            pop cx
            pop bx
            pop ax
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
            cmp [byte ptr ds:[di-1]], ASCNull
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
            ; Reserve registers
            push    ax
            push    cx
            push    di
            push    si
            ; 1 = true, 0 = false
            mov cx, 1
            ; Check length
            mov al, [byte ptr ds:[si+1]]
            cmp [byte ptr ds:[di+1]], al
            jne not_equal
            ; StrBuffer.chars
            add di, 2
            add si, 2
        compare_loop:
            mov al, [byte ptr ds:[si]]
            cmp [byte ptr ds:[di]], al
            jne not_equal
            inc di
            inc si
            cmp [byte ptr ds:[di]], ASCNull
            je comp
            jmp compare_loop

        not_equal:
            mov cx, 0
            jmp comp

        comp:
            cmp cx, 1    

            ; Restore registers
            pop    si
            pop    di
            pop    cx
            pop    ax
            ret
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
