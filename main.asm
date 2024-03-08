.MODEL small
.STACK 64

.DATA
    ; strings db 100*256 dup(0)
    oneChar db ''

.CODE
    main proc
        read_next:
            mov ah, 3Fh
            mov bx, 0h          ; stdin handle
            mov cx, 1           ; 1 byte to read
            mov dx, offset oneChar    ; read to ds:dx 
            int 21h             ;  ax = number of bytes read
            or ax,ax
            jnz read_next
    main endp
end main