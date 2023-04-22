

; Description: Creates a user-defined function.
; Input: DL = user type (1 = admin, 2 = subadmin, 3 = user)
;        DH = active (1 = active, 0 = inactive)
;        USES usernameBuffer, passwordBuffer
createUser proc
    
    mov bx, free_address
    cmp bx, 0 ; [NULL] address
    jne not_first_user 

    lea bx, data_block
    
    not_first_user:
    mov si, bx ; si = next free address

    ; Set current address
    mov [si], bx

    ; Set the previos user's next address to the current address
    mov di, last_user_address
    cmp di, 0 ; [NULL] address
    je noPrevUser
    
    add di, 2 ; skips user's address
    mov word ptr [di], bx ; Set the next address to the current address

    noPrevUser:
    mov last_user_address, si

    ; Set the next user's address to 0 [NULL]
    add si, 2 ; skips new user's address
    mov word ptr [si], 0

    ; Sets first game address to 0 [NULL]
    add si, 2 ; skips new user's next address
    mov word ptr [si], 0

    ; Sets user's type
    add si, 2 ; skips new user's first game address
    mov [si], dl

    ; Sets user's active status
    add si, 1 ; skips new user's type
    mov [si], dh

    ; Sets user's username
    add si, 1 ; skips new user's active status
    
    lea di, usernameBuffer
    ; di -> max chars
    ; di+1 -> received chars
    ; di+2 -> username

    xor cx, cx
    mov cl, [di+1] ; cl = received chars
    mov [si], cl ; Sets user's username length

    add si, 1 ; skips new user's username length

    add di, 2 ; skips max chars and received chars
    copy_username:
        mov al, [di]
        mov [si], al
        inc di
        inc si
        loop copy_username

    ; Sets user's password
    add si, cx ; skips new user's username
    
    lea di, passwordBuffer
    ; di -> max chars
    ; di+1 -> received chars
    ; di+2 -> password

    xor cx, cx
    mov cl, [di+1] ; cl = received chars
    mov [si], cl ; Sets user's password length

    add si, 1 ; skips new user's password length

    add di, 2 ; skips max chars and received chars
    copy_password:
        mov al, [di]
        mov [si], al
        inc di
        inc si
        loop copy_password

    add si, cx ; skips new user's password


    mov free_address, si

    ; * Debug
    ; mov byte ptr [si], '$' 
    ; lea di, data_block
    ; mPrintAddress di
    ; mWaitForEnter

    ret
createUser endp


createAdmin proc

    call reinitUsernameBuffer
    mov si, 0
    mov usernameBuffer[si], 0feh

    inc si
    xor cx, cx
    mov cx, sizeof admin_username
    mov usernameBuffer[si], cl
    inc si

    lea di, admin_username

    copy_admin_username:
        mov al, [di]
        mov usernameBuffer[si], al
        inc si
        inc di
        loop copy_admin_username    

    call reinitPasswordBuffer
    mov si, 0
    mov passwordBuffer[si], 0feh

    inc si
    xor cx, cx
    mov cx, sizeof admin_password
    mov passwordBuffer[si], cl
    inc si

    lea di, admin_password

    copy_admin_password:
        mov al, [di]
        mov passwordBuffer[si], al
        inc si
        inc di
        loop copy_admin_password

    mov dl, 1 ; admin
    mov dh, 1 ; active

    call createUser

    ret
createAdmin endp

 
; Description: Waits for user input and stores the input in the usernameBuffer.
getUsernameInput proc

    push ax
    push bx
    push cx
    push dx

    call reinitUsernameBuffer

    mov si, 0
    mov usernameBuffer[si], 0feh

    lea dx, usernameBuffer 
    mov ah, 0ah
    int 21h

    pop dx
    pop cx
    pop bx
    pop ax

    ret
getUsernameInput endp

; Description: Waits for user input and stores the input in the passwordBuffer.
getPasswordInput proc

    push ax
    push bx
    push cx
    push dx

    call reinitPasswordBuffer

    mov si, 0
    mov passwordBuffer[si], 0feh

    lea dx, passwordBuffer 
    mov ah, 0ah
    int 21h

    pop dx
    pop cx
    pop bx
    pop ax

    ret
getPasswordInput endp

reinitUsernameBuffer proc
    mReinitBuffer usernameBuffer
    ret
reinitUsernameBuffer endp

reinitPasswordBuffer proc
    mReinitBuffer passwordBuffer
    ret
reinitPasswordBuffer endp


loginMenu proc
    
    login_loop:

    mPrint newLine
    mPrint newLine
    mPrint sLoginMenu

    mov ah, 10h
    int 16h

    cmp al, 31h ; 1
    je main_login

    cmp al, 32h ; 2
    je end_program

    cmp ah, 42h ; F8
    je create_user
    
    mPrint invalidOption
    mWaitForEnter
    jmp login_loop

    main_login:
    mPrint newLine

    mPrint newLine
    mPrint sUsername
    call getUsernameInput

    mPrint newLine
    mPrint sPassword
    call getPasswordInput

    call authUser

    cmp logged_user_address, 0 ; [NULL] address
    je invalid_login

    cmp logged_user_type, 1 ; admin
    je goToAdminMenu

    cmp logged_user_type, 2 ; subadmin
    je goToSubAdminMenu

    cmp logged_user_type, 3 ; user
    je goToUserMenu

    goToAdminMenu:
    call adminMenu
    jmp end_login

    goToSubAdminMenu:
    call subAdminMenu
    jmp end_login

    goToUserMenu:
    call userMenu
    jmp end_login

    create_user:
    mPrint newLine

    mPrint sUsername
    call getUsernameInput

    mPrint newLine

    mPrint sPassword
    call getPasswordInput

    mov dl, 3 ; user
    mov dh, 0 ; inactive
    call createUser
    jmp login_loop

    invalid_login:
    mPrint newLine
    mPrint sInvalidLogin
    mWaitForEnter
    jmp login_loop

    end_login:

    ret
loginMenu endp


; Description: veryfies if the username and password are correct.
; Input: usernameBuffer, passwordBuffer
; Output: logged_user_address
authUser proc

    lea si, data_block ; first user address

    registered_user_loop:
        mov bx, [si] ; bx = user address

        cmp bx, 0 ; [NULL] address
        je end_auth

        mov si, bx ; si = user address
        ; search for the username
        ; si + 2 -> skip user's address
        ; si + 2 + 2 -> skip user's next address
        ; si + 2 + 2 + 2 -> skip user's first game address

        ; search for the user type
        add si, 6
        mov al, [si] ; al = user type
        mov logged_user_type, al ; save user type

        inc si ; si = user active status
        mov al, [si] ; al = user active status
        cmp al, 0 ; al = 0 if inactive, 1 if active
        je is_not_the_user

        inc si ; si = username length address
        xor cx, cx
        mov cl, [si] ; cl = username length
        add si, 1 ; si = username bytes
        lea di, usernameBuffer
        add di, 2 ; di = username bytes
        push si ; save username address
        push bx ;?
        push cx ; save username length

        call compareStrings

        pop cx ; restore username length
        pop bx ;?
        pop si ; restore username address
        cmp dx, 0 ; dx = 0 if equal, 1 if not equal
        jne is_not_the_user

        ; search for the password
        add si, cx ; si = password length
        xor cx, cx
        mov cl, [si] ; cl = password length
        add si, 1 ; si = password bytes
        lea di, passwordBuffer
        add di, 2 ; di = password bytes
        push si ; save password address
        push bx ;?

        call compareStrings
        
        pop bx ;?
        pop si ; restore password address
        cmp dx, 0 ; dx = 0 if equal, 1 if not equal
        je end_auth ; if password is correct, end auth

        is_not_the_user:
            mov si, bx ; si = first user address
            add si, 2 ; si = next user address
            jmp registered_user_loop

    end_auth:
        mov logged_user_address, bx

    ret
authUser endp

adminMenu proc
    
    print_admin_options:
        mPrint newLine
        mPrint newLine
        mPrint sInitGame
        mPrint sDeactivateUser
        mPrint sActivateUser
        mPrint sTop10GlobalTimes
        mPrint sTop10GlobalScores
        mPrint sExitMenu
        
        mov ah, 10h
        int 16h

        cmp al, 31h ; 1
        je admin_init_game

        cmp al, 32h ; 2
        je admin_deactivate_user

        cmp al, 33h ; 3
        je admin_activate_user

        cmp al, 34h ; 4
        je admin_top10_global_times

        cmp al, 35h ; 5
        je admin_top10_global_scores

        cmp al, 36h ; 6
        je end_admin_menu
        
        mPrint invalidOption
        mWaitForEnter
        jmp print_admin_options

        admin_init_game:
            call startGame
            jmp print_admin_options

        admin_deactivate_user:
            call deactivateUser
            jmp print_admin_options
            
        admin_activate_user:
            call activateUser
            jmp print_admin_options

        admin_top10_global_times:
            jmp print_admin_options

        admin_top10_global_scores:
            jmp print_admin_options

    end_admin_menu:
    ret ; -> Exit menu
adminMenu endp

subAdminMenu proc
    
    ret ; -> Exit menu
subAdminMenu endp

userMenu proc
    
    ret ; -> Exit menu
userMenu endp


deactivateUser proc
    mov cl, 1 ; first non-admin user

    select_user_loop_inactive:
        call getUserByIndex
        cmp bx, 0 ; [NULL] address
        je deactivate_null_user
        
        
        mov si, bx ; si = user address
        add si, 7 ; si = user active status
        mov al, [si] ; al = user active status
        cmp al, 0 ; al = 0 if active
        je skip_inactive_user

        mPrint newLine
        mPrint sSelectedUser

        push cx ; save user index
        add si, 1 ; si = username length address
        mov cl, [si] ; cl = username length
        add si, 1 ; si = username bytes
        call copyStringInBuffer
        lea di, stringCopyBuffer
        mPrintAddress di

        mPrint newLine

        mPrint sInactiveUser ; a
        mPrint sNextUser ; d
        mPrint sBack ; r

        pop cx ; restore user index

        mov ah, 10h
        int 16h

        cmp al, 61h ; a
        je innactivate_selected_user

        cmp al, 64h ; d
        je skip_inactive_user

        cmp al, 72h ; r
        je end_user_inactivation

        mPrint invalidOption
        mWaitForEnter
        jmp select_user_loop_inactive

        deactivate_null_user:
            mPrint sNotFoundUser
            mWaitForEnter
            jmp end_user_inactivation
        
        skip_inactive_user:
            inc cl ; cl = cl + 1
            jmp select_user_loop_inactive

        innactivate_selected_user: 
            mov si, bx ; si = user address
            add si, 7 ; si = user active status
            mov al, 0 ; al = 0
            mov [si], al ; user active status = 0
            
            mPrint sUserDeactivated
            mWaitForEnter
            jmp skip_inactive_user
            

    end_user_inactivation:
    ret
deactivateUser endp


activateUser proc

    mov cl, 1 ; first non-admin user

    select_user_loop:
        call getUserByIndex
        cmp bx, 0 ; [NULL] address
        je activate_null_user
        
        
        mov si, bx ; si = user address
        add si, 7 ; si = user active status
        mov al, [si] ; al = user active status
        cmp al, 1 ; al = 1 if active
        je skip_active_user

        mPrint newLine
        mPrint sSelectedUser

        push cx ; save user index
        add si, 1 ; si = username length address
        mov cl, [si] ; cl = username length
        add si, 1 ; si = username bytes
        call copyStringInBuffer
        lea di, stringCopyBuffer
        mPrintAddress di

        mPrint newLine

        mPrint sAcceptUser ; a
        mPrint sAcceptUser2 ; s
        mPrint sNextUser ; d
        mPrint sBack ; r

        pop cx ; restore user index

        mov ah, 10h
        int 16h

        cmp al, 61h ; a
        je accept_selected_user

        cmp al, 73h ; s
        je accept_selected_user_as_admin

        cmp al, 64h ; d
        je skip_active_user


        cmp al, 72h ; r
        je end_user_activation

        mPrint invalidOption
        mWaitForEnter
        jmp select_user_loop

        activate_null_user:
            mPrint sNotFoundUser
            mWaitForEnter
            jmp end_user_activation
        
        skip_active_user:
            inc cl ; cl = cl + 1
            jmp select_user_loop

        accept_selected_user: 
            mov si, bx ; si = user address
            add si, 7 ; si = user active status
            mov al, 1 ; al = 1
            mov [si], al ; activate user
            
            mPrint sUserActivated
            mWaitForEnter
            jmp skip_active_user
            
        accept_selected_user_as_admin: 
            mov si, bx ; si = user address
            add si, 6 ; si = user type address
            mov al, 2 ; al = 2 ; subadmin
            mov [si], al ; activate user
            add si, 1 ; si = user active status
            mov al, 1 ; al = 1
            mov [si], al ; activate user
            
            mPrint sUserActivated
            mWaitForEnter
            jmp skip_active_user

    end_user_activation:
    ret
activateUser endp

; Description: Get the user address by index
; Input: CL = user index
; Output: BX = user address | 0 if not found
getUserByIndex proc

    push cx ; save user index    
    lea si, data_block ; first user address

    registered_user_loop:
        mov bx, [si] ; bx = user address

        cmp bx, 0 ; [NULL] address
        je return_user

        cmp cl, 0 ; cl = 0 if is the user
        je return_user

        dec cl ; cl = cl - 1

        mov si, bx ; si = first user address
        add si, 2 ; si = next user address
        jmp registered_user_loop


    return_user:
    pop cx ; restore user index
    ret
getUserByIndex endp


; Description: Copies a string into a $ buffer
; Input: CL=chars to copy, SI=source address
; Output: stringCopyBuffer
copyStringInBuffer proc

    mov ch, 0
    ; reset stringCopyBuffer
    push cx

    lea di, stringCopyBuffer
    mov cl, 20
    mov al, '$'

    reset_copy_buffer:
        mov [di], al
        inc di
        loop reset_copy_buffer

    pop cx
    ; copy string
    
    lea di, stringCopyBuffer

    copy_string:
        mov al, [si]
        mov [di], al
        inc si
        inc di
        loop copy_string

    ret
copyStringInBuffer endp