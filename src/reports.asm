

; Description: Generate the top10.txt file
; Input: AddressArray with the ordered addresses
; Output: File top10.txt with the top 10 addresses
generateReport proc
    
    ; Create file
    mov cx, 0 ; Read-only
    mov dx, offset top10File
    mov ah, 3ch
    int 21h
    jc create_file_error

    mov filehandle, ax

    ; Write to file
    mWriteIndDoc sSeparator
    call writeNewLine

    mWriteIndDoc initialMessage
    call writeNewLine

    mWriteIndDoc sSeparator
    call writeNewLine

    mWriteIndDoc sDeveloper
    call writeNewLine

    mWriteIndDoc sSeparator
    call writeNewLine

    call writeReportHeader

    call writeReportContent

    ; Close file
    mov bx, filehandle
    mov ah, 3eh
    int 21h
    jmp end_report_generation

    create_file_error:
        mPrint errorMessage

    end_report_generation:
    ret
generateReport endp

writeNewLine proc
    mWriteIndDoc newLine
    ret
writeNewLine endp


; Description: Write the report header
writeReportHeader proc
    
    mWriteIndDoc sType

    ; cmp selected_algorithm, 0
    ; je writeBubbleSort

    mWriteIndDoc sBubbleSort

    mWriteIndDoc sOrientation


    cmp orientation, 0
    je writeAscending

    mWriteIndDoc sDesc
    jmp end_write_orientation

    writeAscending:
        mWriteIndDoc sAsc

    end_write_orientation:
    call writeTimes

    mWriteIndDoc sSeparator

    mWriteIndDoc sHeader

    cmp metric, 1
    je write_score_metric

    mWriteIndDoc sTimeProp

    jmp end_write_metric

    write_score_metric:
        mWriteIndDoc sScore

    end_write_metric:

    call writeNewLine
    
    mWriteIndDoc sSeparator

    ret
writeReportHeader endp


; Description: Write the date and time of the report
writeTimes proc
    
    mWriteIndDoc sDate

    mov ah, 2ah
    int 21h
    ; DL = day, DH = month, CX = year

    ; Write day
    mov ax, 0
    mov al, dl
    call write2DigitNumber

    mWriteIndDoc dateDelimiter

    ; Write month
    mov ah, 2ah
    int 21h
    mov ax, 0
    mov al, dh
    call write2DigitNumber

    mWriteIndDoc dateDelimiter

    ; Write year
    mov ah, 2ah
    int 21h
    mov ax, cx
    call write2DigitNumber


    ; ----- HOUR -----
    call writeNewLine
    mWriteIndDoc sTime

    mov ah, 2ch
    int 21h
    ; CH = hour, CL = minute, DH = second

    ; Write hour
    mov ax, 0
    mov al, ch
    call write2DigitNumber

    mWriteIndDoc hourDelimiter

    ; Write minute
    mov ah, 2ch
    int 21h
    mov ax, 0
    mov al, cl
    call write2DigitNumber

    mWriteIndDoc hourDelimiter

    ; Write second
    mov ah, 2ch
    int 21h
    mov ax, 0
    mov al, dh
    call write2DigitNumber

    call writeNewLine
    
    ret
writeTimes endp

; Description: Write the top 10 addresses
; Input: 
; Output: 
write2DigitNumber proc
    call numberToString
    lea dx, numberString
    add dx, 4 ; Last 2 digits of the day
    mov bx, filehandle
    mov cx, 2
    mov ah, 40h
    int 21h
    ret
write2DigitNumber endp


; Description: Write the top 10 addresses
writeReportContent proc

    mov cx, addressSize
    mov ax, 0 ; correlative

    lea si, addressArray ; addressArray address

    write_game_info:
        cmp cx, 0
        je end_write_game_info

        dec cx
        push cx

        ; Write correlative
        inc ax

        push ax

        call numberToString
        lea di, numberString
        add di, 4 ; Last 2 digits
        mWriteValueInDoc di, 2h

        ; write spaces
        mWriteIndDoc sSpace
        mWriteIndDoc sSpace
        mWriteIndDoc sSpace
        mWriteIndDoc sSpace

        ; write username
        mov di, [si] ; DI = addressArray[i]
        add di, 09h 
        mov bx, [di] ; BX = addressArray[i].user
        add bx, 8 ; BX = adress of username size
        xor dx, dx
        mov dl, [bx] ; DL = username size
        inc bx ; BX = address of username
        mov di, bx ; DI = address of username
        mWriteValueInDoc di, dx


        ; write spaces
        mWriteIndDoc sSpace

        ; write score
        mov di, [si] ; DI = addressArray[i]
        add di, 08h 
        push ax

        xor ax, ax
        mov al, [di] ; AL = addressArray[i].score
        call numberToString
        lea di, numberString
        add di, 5 ; Last digit
        mWriteValueInDoc di, 1h


        pop ax

        mWriteIndDoc sSpace
        mWriteIndDoc sSpace
        mWriteIndDoc sSpace

        ; Metric

        mov bx, [si] ; BX = game address

        cmp metric, 1
        je write_score_content
        
        call getTimeFromGame

        push ax 
        mov ax, dx

        mov bx, 64h ; BX = 100
        xor dx, dx
        div bx ; AX = AX / 100

        call numberToString
        lea di, numberString
        mWriteValueInDoc di, 6h
        pop ax

        jmp end_write_score_content

        write_score_content:
        call getScoreFromGame

        push ax 
        
        mov ax, dx
        call numberToString
        lea di, numberString
        mWriteValueInDoc di, 6h

        pop ax

        end_write_score_content:

        call writeNewLine

        pop ax
        add si, 2 ; Next address on the array
        pop cx
        jmp write_game_info

    end_write_game_info:
    ret
writeReportContent endp


; Description: Moves through memory
memoryReport proc
    
    ; Create file
    mov cx, 0 ; Read-only
    mov dx, offset memoryReportFile
    mov ah, 3ch
    int 21h
    jc mem_create_file_error

    mov filehandle, ax

    ; PUML header
    mWriteIndDoc sPumlHeader

    ; content

    lea si, data_block
    call writeMemoryUser

    ; PUML content
    mWriteIndDoc sPumlFooter
    
    ; Close file
    mov bx, filehandle
    mov ah, 3eh
    int 21h
    jmp mem_end_report_generation
    mem_create_file_error:
        mPrint errorMessage

    mem_end_report_generation:
    ret
memoryReport endp


; Description: Write user data as json
; Input: SI = user address
writeMemoryUser proc
    
    mov ax, [si]
    cmp ax, 0 ; Null address
    je end_write_memory_user

    mov bx, [si]
    mov si, bx ; SI = user address

    push si

    ; Write {
    mWriteIndDoc sMemoryLBrace

    ; write address
    mWriteIndDoc sMemoryAddress
    call writeJsonPropInDoc
    mWriteIndDoc sMemoryComma

    ; write next user address
    add si, 2
    mWriteIndDoc sMemoryNextUser
    call writeJsonPropInDoc
    mWriteIndDoc sMemoryComma

    ; write first game address
    add si, 2
    mWriteIndDoc sMemoryFirstGame
    call writeJsonPropInDoc
    mWriteIndDoc sMemoryComma

    ; write type
    add si, 2
    mWriteIndDoc sMemoryUserType
    call writeJson8BitPropInDoc
    mWriteIndDoc sMemoryComma

    ; write active status
    add si, 1
    mWriteIndDoc sMemoryUserActive
    call writeJson8BitPropInDoc
    mWriteIndDoc sMemoryComma

    ; write username length
    add si, 1
    mWriteIndDoc sMemoryUsernameLength
    call writeJson8BitPropInDoc
    mWriteIndDoc sMemoryComma

    ; write username
    mWriteIndDoc sMemoryUsername
    call WriteQuoteInDoc
    xor dx, dx
    mov dl, [si] ; DL = username length
    inc si
    mov di, si ; DI = address of username
    add si, dx ; SI = address of next user
    mWriteValueInDoc di, dx
    call WriteQuoteInDoc
    mWriteIndDoc sMemoryComma

    ; Write password length
    mWriteIndDoc sMemoryPasswordLength
    call writeJson8BitPropInDoc
    mWriteIndDoc sMemoryComma

    ; Write password
    mWriteIndDoc sMemoryPassword
    call WriteQuoteInDoc
    xor dx, dx
    mov dl, [si] ; DL = password length
    inc si
    mov di, si ; DI = address of password
    add si, dx ; SI = address of next user
    mWriteValueInDoc di, dx
    call WriteQuoteInDoc
    mWriteIndDoc sMemoryComma

    ; write games: [

    mWriteIndDoc sMemoryGames
    mWriteIndDoc sMemoryLBracket

    pop si ; initial address
    push si
    ; Write games
    add si, 4 ; first game address
    call writeMemoryGame

    ; Write ], 
    mWriteIndDoc sMemoryRBracket
    mWriteIndDoc sMemoryComma

    ; Write next user
    mWriteIndDoc sMemoryUsers
    mWriteIndDoc sMemoryLBracket

    pop si ; initial address
    ; Write next user
    add si, 2 ; next user address
    call writeMemoryUser

    ; Write ]
    mWriteIndDoc sMemoryRBracket

    ; Write }
    mWriteIndDoc sMemoryRBrace

    end_write_memory_user:
    ret
writeMemoryUser endp

; Description: Write game data as json
; Input: SI = game address
writeMemoryGame proc

    mov ax, [si]
    cmp ax, 0 ; Null address
    je end_write_memory_game

    mov bx, [si]
    mov si, bx ; SI = user address

    push si

    ; Write {
    mWriteIndDoc sMemoryLBrace

    ; write address
    mWriteIndDoc sMemoryAddress
    call writeJsonPropInDoc
    mWriteIndDoc sMemoryComma

    ; write next game address
    add si, 2
    mWriteIndDoc sMemoryNextGame
    call writeJsonPropInDoc
    mWriteIndDoc sMemoryComma

    ; write points
    add si, 2
    mWriteIndDoc sMemoryPoints
    call writeJsonPropInDoc
    mWriteIndDoc sMemoryComma

    ; write time
    add si, 2
    mWriteIndDoc sMemoryTime
    call writeJsonPropInDoc
    mWriteIndDoc sMemoryComma

    ; write level
    add si, 2
    mWriteIndDoc sMemoryLevel
    call writeJson8BitPropInDoc
    mWriteIndDoc sMemoryComma

    ; write user reference
    add si, 1
    mWriteIndDoc sMemoryUserAddress
    call writeJsonPropInDoc
    mWriteIndDoc sMemoryComma

    ; write next game: [
    mWriteIndDoc sMemoryNextGame
    mWriteIndDoc sMemoryLBracket

    pop si ; initial address
    add si, 2 ; next game address
    call writeMemoryGame
    
    ; Write ]
    mWriteIndDoc sMemoryRBracket

    ; Write }
    mWriteIndDoc sMemoryRBrace

    end_write_memory_game:
    ret
writeMemoryGame endp

; writes number prop
; Input: DI = address of the number
writeJsonPropInDoc proc
    
    push bx
    push di
    push ax
    ; Write "
    call WriteQuoteInDoc
    pop ax
    pop di

    ; Write number
    mov ax, [si]
    call numberToString
    lea di, numberString

    push di
    push ax
    mWriteValueInDoc di, 6h

    ; Write "

    call WriteQuoteInDoc

    pop ax
    pop di
    pop bx

    ret
writeJsonPropInDoc endp


; writes 8bits number prop
; Input: DI = address of the number
writeJson8BitPropInDoc proc
    
    push bx
    push di
    push ax
    ; Write "
    call WriteQuoteInDoc
    pop ax
    pop di

    ; Write number
    xor ax, ax
    mov al, [si]
    call numberToString
    lea di, numberString

    push di
    push ax
    mWriteValueInDoc di, 6h

    ; Write "
    call WriteQuoteInDoc

    pop ax
    pop di
    pop bx

    ret
writeJson8BitPropInDoc endp

WriteQuoteInDoc proc
    mWriteIndDoc sMemoryQuote
    ret
WriteQuoteInDoc endp