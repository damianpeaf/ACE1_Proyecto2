

; Description: loads a game level from a file
; Input: DX - pointer to the file name
; Output: DX - 1 if error, 0 if success
readLevelFile proc

    ;  OPEN FILE
    mov CX, 00
    mov AL, 00 ; Read only
    mov AH, 3dh ; Open
    int 21
    jc open_file_error
    mov [filehandle], AX 

    ; TODO: Read the file

    jmp close_file

    open_file_error:
        mPrint errorMessage
        mov dx, 1
        jmp end_read

    close_file_error:
        mPrint errorMessage
        mov dx, 1
        jmp end_read

    close_file:
        ; Close the file
        mov bx, [filehandle]
        mov AH, 3eh
        int 21
        jc close_file_error


    end_read:
        ret

readLevelFile endp