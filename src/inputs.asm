mInputVariables macro

usernameBuffer db 100h dup('$')
passwordBuffer db 100h dup('$')

endm


; Description: Waits for the user to press enter
mWaitForEnter macro
    LOCAL press_enter

    push ax

    press_enter:
        mov AH, 08h
        int 21h
        cmp AL, 0dh
        jne press_enter

    pop ax
endm

mReinitBuffer macro buffer

    local reinit_loop

    mov cx, 100h
    mov si, 0
    mov al, '$'

    reinit_loop:
        mov buffer[si], al
        inc si
        loop reinit_loop
endm