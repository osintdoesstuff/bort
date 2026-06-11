; ============================================================================
; VGA TEXT MODE DRIVER - 80x25, 0xB8000
; ============================================================================

VGA_BASE equ 0xB8000
VGA_WIDTH equ 80
VGA_HEIGHT equ 25
; Set color - AL = color (high nibble = bg, low nibble = fg)
vga_set_color:
    mov [vga_color], al
    ret

; Clear screen
vga_clear:
    push eax
    push ecx
    push edi
    mov edi, VGA_BASE
    mov ah, [vga_color]
    mov al, ' '
    mov ecx, VGA_WIDTH * VGA_HEIGHT
    rep stosw
    mov byte [vga_cursor_x], 0
    mov byte [vga_cursor_y], 0
    pop edi
    pop ecx
    pop eax
    call vga_update_cursor
    ret

vga_putchar:
    push eax
    push ebx
    push edi
    
    cmp al, 13          ; CR / Enter
    je .lf
    cmp al, 10          ; LF
    je .lf
    cmp al, 8           ; Backspace
    je .bs
    
    ; Calculate position: (y * 80 + x) * 2 + 0xB8000
    movzx edi, byte [vga_cursor_y]
    imul edi, VGA_WIDTH
    movzx ebx, byte [vga_cursor_x]
    add edi, ebx
    shl edi, 1
    add edi, VGA_BASE
    
    ; Write char + attribute
    mov ah, [vga_color]
    mov [edi], ax
    
    ; Advance cursor
    inc byte [vga_cursor_x]
    cmp byte [vga_cursor_x], VGA_WIDTH
    jb .done
    
.lf:
    mov byte [vga_cursor_x], 0
    inc byte [vga_cursor_y]
    cmp byte [vga_cursor_y], VGA_HEIGHT
    jb .done
    call vga_scroll
    jmp .done
    
.bs:
    cmp byte [vga_cursor_x], 0
    jne .bs_same_line
    
    ; We're at column 0 - need to go to previous line
    cmp byte [vga_cursor_y], 1
    je .done                    ; Can't go back from top-left corner
    
    dec byte [vga_cursor_y]     ; Go up one line
    
    ; Find last non-space character on previous line
    push eax
    push ebx
    push edi
    
    mov bl, VGA_WIDTH - 1       ; Start from end of line
    
.find_last_char:
    ; Calculate position: (y * 80 + x) * 2 + 0xB8000
    movzx edi, byte [vga_cursor_y]
    imul edi, VGA_WIDTH
    movzx eax, bl
    add edi, eax
    shl edi, 1
    add edi, VGA_BASE
    
    mov al, [edi]               ; Get character
    cmp al, ' '                 ; Is it a space?
    jne .found_char             ; Nope, found our spot
    
    dec bl                      ; Keep looking left
    cmp bl, 0
    jge .find_last_char
    
    ; Entire line was spaces, just go to column 0
    xor bl, bl
    
.found_char:
    mov [vga_cursor_x], bl      ; Set cursor to last char
    
    ; Now erase that character
    movzx edi, byte [vga_cursor_y]
    imul edi, VGA_WIDTH
    movzx eax, bl
    add edi, eax
    shl edi, 1
    add edi, VGA_BASE
    
    mov ah, [vga_color]
    mov al, ' '
    mov [edi], ax
    
    pop edi
    pop ebx
    pop eax
    jmp .done
    
.bs_same_line:
    ; Original backspace behavior - just go back one char
    dec byte [vga_cursor_x]
    
    ; Erase the character
    movzx edi, byte [vga_cursor_y]
    imul edi, VGA_WIDTH
    movzx ebx, byte [vga_cursor_x]
    add edi, ebx
    shl edi, 1
    add edi, VGA_BASE
    mov ah, [vga_color]
    mov al, ' '
    mov [edi], ax
    jmp .done

    
.done:
    call vga_update_cursor
    pop edi
    pop ebx
    pop eax
    ret

vga_update_cursor:
    push eax
    push ebx
    push edx
    
    ; Calculate position: y * 80 + x
    movzx eax, byte [vga_cursor_y]
    imul eax, VGA_WIDTH
    movzx ebx, byte [vga_cursor_x]
    add eax, ebx
    mov ebx, eax        ; Save position in ebx
    
    ; Send high byte
    mov dx, 0x3D4
    mov al, 0x0E
    out dx, al
    mov dx, 0x3D5
    mov eax, ebx
    shr eax, 8
    out dx, al
    
    ; Send low byte
    mov dx, 0x3D4
    mov al, 0x0F
    out dx, al
    mov dx, 0x3D5
    mov eax, ebx
    out dx, al
    
    pop edx
    pop ebx
    pop eax
    ret

; Print string - ESI = null-terminated string
vga_print:
    push eax
    push esi
.loop:
    lodsb
    test al, al
    jz .done
    call vga_putchar
    jmp .loop
.done:
    pop esi
    pop eax
    ret

; Scroll screen up one line
vga_scroll:
    push eax
    push ecx
    push esi
    push edi
    
    ; Move lines 1-24 up to 0-23
    mov edi, VGA_BASE
    mov esi, VGA_BASE + (VGA_WIDTH * 2)
    mov ecx, VGA_WIDTH * (VGA_HEIGHT - 1)
    rep movsw
    
    ; Clear last line
    mov ah, [vga_color]
    mov al, ' '
    mov ecx, VGA_WIDTH
    rep stosw
    
    mov byte [vga_cursor_y], VGA_HEIGHT - 1
    
    pop edi
    pop esi
    pop ecx
    pop eax
    ret

; Print EAX as hex
vga_hex32:
    push eax
    push ecx
    mov ecx, 8
.loop:
    rol eax, 4
    push eax
    and al, 0x0F
    add al, '0'
    cmp al, '9'
    jbe @f
    add al, 7
@@: call vga_putchar
    pop eax
    loop .loop
    pop ecx
    pop eax
    ret
; Toggle between blink and high-intensity background
; Bit 7 of color: blink (default) OR bright background (if toggled)
vga_toggle_blink:
    push eax
    push edx
    
    ; Reset attribute controller flip-flop
    mov dx, 0x3DA       ; Input Status Register 1
    in al, dx
    
    ; Select Mode Control Register (index 0x10)
    mov dx, 0x3C0       ; Attribute Controller Address/Data
    mov al, 0x10
    out dx, al
    
    ; Read current value
    inc dx              ; 0x3C1 - Attribute Controller Data Read
    in al, dx
    dec dx              ; Back to 0x3C0
    
    ; Toggle bit 3 (Blink Enable)
    ; Bit 3 = 1: Blink enabled (default)
    ; Bit 3 = 0: Blink disabled, bit 7 = high intensity BG
    xor al, 0x08
    
    ; Write it back
    push eax
    mov al, 0x10
    out dx, al
    pop eax
    out dx, al
    
    ; Re-enable video (bit 5 must be set)
    or al, 0x20
    push eax
    mov al, 0x10
    out dx, al
    pop eax
    out dx, al
    
    pop edx
    pop eax
    ret