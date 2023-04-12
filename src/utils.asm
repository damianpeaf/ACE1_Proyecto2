mPrint macro variable
    push ax
    push dx

    mov dx, offset variable
    mov ah, 09h
    int 21h

    pop dx
    pop ax
endm


mPrintAddress macro address
    mov dx, address
    mov ah, 09h
    int 21h
endm

mPrint8Reg macro reg

    push ax
    push dx

    mov ax, 0
    mov al, reg
    mNumberToString
    mPrint numberString

    pop dx
    pop ax

endm

mPrintDWVariable macro variable
    push ax
    push dx

    mov ax, [variable]
    mNumberToString
    mPrint numberString

    pop dx
    pop ax
endm

            
mPrintDBVariable macro variable
    push ax
    push dx

    mov ax, 0
    mov al, [variable]
    mNumberToString
    mPrint numberString

    pop dx
    pop ax
endm  