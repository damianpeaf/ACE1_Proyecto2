mStringVariables macro
    numberString db 6 dup ("$")
    numberStringEnd db "$"
    xd db "$"
    
    numberRepresentationError db "El numero no puede ser representado", 0dh, 0ah, "$"
    
    negativeNumber db 0

    rowHeader db 2 dup (?)
    rowHeaderEnd db "$"

    maxReprestableNumber equ 7fffh
endm


; Description: Converts a sign number of 16 bits to an ascii representation string
; Input : AX - number to convert
; Output: DX - 0 if no error, 1 if error
;         numberString - the string representation of the number
mNumberToString macro

    LOCAL convert_positive, convert_negative, extract_digit, representation_error, fill_with_0, set_digit, end, empty_stack, set_negative
    
    ; REGISTER PROTECTION
    push ax
    push bx
    push cx
    push si
    
    mov cx, 0
    ; Comparte if its a negative number
    mov negativeNumber, 0
    cmp ax, 0
    jge convert_positive

    convert_negative:
        mov negativeNumber, 1 ; Set the negative number flag to 1
        inc cx

        ; Convert to positive
        neg ax
        jmp convert_positive
    
    convert_positive:
        mov bx, 0ah

        extract_digit:
            mov dx, 0 ; Clear the dx register [Remainder]
            div bx ; Divide the AX number by 10 and store the remainder in dx
            add dl, '0' ; Convert the remainder to ascii
            push dx ; Push the remainder to the stack
            inc cx ; Increment the digit counter
            cmp ax, 0 ; Check if the number is 0
            jne extract_digit ; If not, extract the next digit

    ; No representable number
    cmp cx, 6
    jg representation_error

    ; ------------------- Fill the string -------------------
    mov si, 0

    ; ! Fill with 0 every digit that is not used <- Change this to fill with spaces
    mov dx, 6
    sub dx, cx
    cmp dx, 0
    jz set_negative

    fill_with_0:
        mov numberString[si], '0'
        inc si
        dec dx
        jnz fill_with_0

    set_negative:

    ; If the number is negative, add the '-' sign
    cmp negativeNumber, 1
    jne set_digit
    mov numberString[si], '-'
    inc si
    dec cx

    ; Copy the digits to the string
    set_digit:
        pop dx
        mov numberString[si], dl
        inc si
        loop set_digit

    mov dx, 0 ; NO ERROR
    jmp end

    representation_error:
        mPrint numberRepresentationError

        ; empty the stack
        empty_stack:
            pop dx
            loop empty_stack

        mov dx, 1 ; ERROR

    end:
        ; REGISTER RESTORATION
        pop si
        pop cx
        pop bx
        pop ax

endm

; Description: Converts a string to a sign number of 16 bits
; Input : None, uses the [numberString] variable and the [negativeNumber] variable
; Output: saves the number in [numberReference] variable
;         DX - 0 if no error [No representable number], 1 if error
mStringToNumber macro

    local eval_digit, error, end, save

    ; Register protection
    push ax
    push bx
    push cx
    push si
    push di

    mov bx, 0ah
    mov si, 0
    mov ax, 0
    mov dx, 0

    eval_digit:
        mul bx
        mov dl, numberString[si]
        sub dl, '0'
        add ax, dx

        inc si

        cmp numberString[si], "$"
        jne eval_digit

    ; represetable number validation
    cmp ax, maxReprestableNumber
    ja error

    cmp negativeNumber, 1
    jne save

    neg ax

    save:
        mov dx, 0
        mov numberReference, ax
        jmp end

    error:
        mPrint numberRepresentationError
        mPrint newLine
        
        mov dx, 1
        jmp end

    end: 
        ; Register restoration
        pop di
        pop si
        pop cx
        pop bx
        pop ax

endm

; Description: Compares two strings
; Input : DI - string 1 address
;         SI - string 2 address
;         CX - Characters to compare
; Output: DX - 0 if equal, 1 if not equal
mCompareStrings macro

    LOCAL compare, end

    ; REGISTER PROTECTION
    push ax
    push bx
    push cx
    push si
    push di

    mov dx, 1 ; Not equal
    compare:
        mov al, [di]
        mov bl, [si]
        cmp al, bl
        jne end
        inc di
        inc si
        loop compare

    mov dx, 0 ; Equal
    jmp end

    end:
        ; REGISTER RESTORATION
        pop di
        pop si
        pop cx
        pop bx
        pop ax
endm


mResetNumberString macro
    local reset

    push cx
    push si

    mov cx, 6
    mov si, 0

    reset:
        mov numberString[si], "$"
        inc si
        loop reset

    pop si
    pop cx
endm