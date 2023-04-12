mInputVariables macro

commandBuffer db 100h dup('$')
comamandEnd dw '$'
charValue db 0
charEnd db '$'

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


; Description: Waits for user input and stores it in the commandBuffer
;              Resets the commandBuffer before reading the input
; Input: None
; Output: None
mWaitForInput macro

    local reinit_loop

    push ax
    push bx
    push cx
    push dx

    ; reinit buffer
    mov cx, 100h
    mov si, 0
    mov al, '$'

    reinit_loop:
        mov commandBuffer[si], al
        inc si
        loop reinit_loop

    mov si, 0
    mov commandBuffer[si], 0feh

    lea dx, commandBuffer 
    mov ah, 0ah
    int 21h

    pop dx
    pop cx
    pop bx
    pop ax

endm

; Description: Skips all white spaces until the first non white space character
; Input: SI - absolute address of the buffer
; Output: SI - absoulte address of the first non white space character
mSkipWhiteSpaces macro

    local skip_white_spaces, end
    push ax

    ; skip white spaces
    skip_white_spaces:
        mov al, [si]
        cmp al, ' '
        jne end
        inc si
    end:
        pop ax

endm

mSkipUntilWhiteSpaces macro

    local skip_until_white_spaces, end

    push ax

    ; skip until white spaces
    skip_until_white_spaces:
        mov al, [si]
        cmp al, ' '
        je end
        mPrintAddress si
        mWaitForEnter
        inc si
    end:
        pop ax
endm


mPrintChar macro char

    push ax
    push si
    push dx
    
    mov [charValue], char
    mov [charEnd], '$'

    mPrint charValue

    pop dx
    pop si
    pop ax

endm