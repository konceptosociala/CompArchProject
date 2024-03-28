; HEADER
IDEAL
MODEL small
STACK 64

; CONSTANTS
BufSize         EQU     255             ; Maximum string size (<=255)
ASCNull         EQU     0               ; ASCII null
ASCcr           EQU     13              ; ASCII carriage return
ASClf           EQU     10              ; ASCII line feed 
true            EQU     1
false           EQU     0

; STRUCTURES
STRUC ParseData
 index          db 255
 occs           db 255
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
            ; ParseData counter
            mov cx, 0
        process_strings:
            mov si, offset sub_string
            mov di, offset tmp_string
            ; Read string
            call ClearString
            call ReadString
            call StrLength
            mov [tmp_string.strlen], dl
            ; Check if EOF
            cmp [byte ptr ds:[di+1]], 0
            je exit
            ; Process string
            call ProcessString  
            ; Inc counter
            inc cx
            ; Loop          
            jmp process_strings
        sorting:
            ; TODO: sorting
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
            mov [sub_string.strlen], dl
            ; Restore registers
            pop bx
            pop cx
            pop di
            pop si  
            ret
    ENDP    GetSubstring

    PROC    ProcessString
            ; Reserve registers
            push ax
            push bx
            push cx
            push dx
            push di
            ; Setup ParseData
            mov bp, 0
            add bp, offset parse_data
            mov ax, 2
            mul cx
            add bp, ax
            mov [byte ptr ds:[bp]], cl
            mov [byte ptr ds:[bp+1]], 0
        find_occurances:
            ; Substr len
            xchg di, si
            call StrLength
            xchg di, si
            cmp dl, [tmp_string.strlen]
            jg end_process
            ; Get strpos
            call StrPos
            ; Check if found
            cmp dl, 255
            je occurance_not_found
            jne occurance_found
        occurance_not_found:
            mov dx, 1
            call StrTrimStart
            jmp find_occurances
        occurance_found:
            add dl, [sub_string.strlen]
            dec dl
            call StrTrimStart
            inc [byte ptr ds:[bp+1]]
            jmp find_occurances
        end_process:
            ; Restore registers               
            pop di
            pop dx
            pop cx
            pop bx
            pop ax
            ret
    ENDP    ProcessString

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
    ;       di = address of string
    ; 
    ;  OUT: dx = number of non-null characters in s
    ;---------------------------------------------------------------
    PROC    StrLength
            push ax
            push di

            mov dx, 0
            add di, 2
        count:
            inc di      
            inc dx              
            cmp [byte ptr ds:[di-1]], ASCNull
            jne count

            dec dx
            pop di 
            pop ax
            ret
    ENDP    StrLength

    ;---------------------------------------------------------------
    ;       si = address of string 1
    ;       di = address of string 2 
    ; 
    ;  OUT: flags set for conditional jump using je
    ;---------------------------------------------------------------
    PROC    StrCompare
            ; Reserve registers
            push    ax
            push    cx
            push    di
            push    si
            ; 1 = true, 0 = false
            mov cx, true
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
            mov cx, false
            jmp comp

        comp:
            cmp cx, true  

            ; Restore registers
            pop    si
            pop    di
            pop    cx
            pop    ax
            ret
    ENDP    StrCompare

    ;---------------------------------------------------------------
    ;       si = address of substring to find
    ;       di = address of target string to scan
    ;       
    ;  OUT: dx = idx of substring; 255 == undefined
    ;---------------------------------------------------------------
    PROC    StrPos
            ; Reserve registers
            push ax
            push bx
            push cx
            push di
            push si
            ; Pos of substr == undefined
            mov dl, 255
            mov cl, false
            ; DH = Target idx
            mov dh, 0
            ; Str loop
        str_pos_loop_str:
            cmp dh, [di+1]
            je str_pos_end
            ; Has substring
            mov cl, true
            ; CH = Sub idx
            mov ch, 0
            inc dh
            ; Substr loop
        str_pos_loop_substr:
            cmp ch, [si+1]
            je str_pos_check_eq
            inc ch

            mov ax, di 
            add al, dh
            add al, ch
            mov bx, si
            add bl, ch
            add bl, 1

            ;-----------
            ; temporarily replace bx and ax, because `mov al, [ax]` doesn't work
            push bx
            mov bx, ax
            mov al, [bx]
            mov ah, 0
            pop bx
            mov bl, [bx]
            mov bh, 0
            ;-----------

            cmp ax, bx
            je str_pos_loop_substr
            jne str_pos_char_neq

        str_pos_char_neq:
            mov cl, false
            jmp str_pos_loop_str

        str_pos_check_eq:
            cmp cl, true
            je str_pos_is_eq
            jne str_pos_loop_str

        str_pos_is_eq:
            mov dl, dh
            mov dh, 0
            jmp str_pos_end

        str_pos_end:        
            ; Restore registers
            pop si
            pop di
            pop cx
            pop bx
            pop ax
            ret
    ENDP    StrPos

    ;---------------------------------------------------------------
    ;       di = address of target string to trim
    ;       dx = characters to trim
    ;
    ;  OUT: 
    ;---------------------------------------------------------------
    PROC    StrTrimStart
            ; Reserve registers
            push ax
            push bx
            push cx
            push di
            push si
            push bp
            mov bp, 0
            ; Old length
            mov ch, [ds:[di+1]]
            ; Set length
            sub [ds:[di+1]], dx
            ; Counter
            mov ax, 0
        str_trim_start_loop:
            ; BX = [di + 2 + ax + dx]
            mov bx, di
            add bx, 2
            add bx, ax
            add bx, dx
            mov bl, [bx]
            mov bh, 0
            ; BP = di + 2 + ax
            mov bp, di
            add bp, 2
            add bp, ax
            ; Check if already null
            cmp [byte ptr ds:[bp]], ASCNull
            je str_trim_start_clear
            mov [byte ptr ds:[bp]], bl
            inc al
            cmp al, [di+1]
            jne str_trim_start_loop

        str_trim_start_clear:
            ; BP = di + 2 + ax
            mov bp, di
            add bp, 2
            add bp, ax
            mov [byte ptr ds:[bp]], ASCNull
            inc al
            cmp al, ch
            jne str_trim_start_clear

            ; Restore registers
            pop bp
            pop si
            pop di
            pop cx
            pop bx
            pop ax
            ret
    ENDP    StrTrimStart

END START
