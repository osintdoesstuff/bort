; ============================================================================
; SERIAL PORT DRIVER - COM1, 115200 baud, 8N1
; ============================================================================
db "SRL DRV", 0, 0, 0, 0

COM1 equ 0x3F8
serial_init:

    mov dx, COM1 + 1
    xor al, al
    out dx, al          ; Disable interrupts
    
    mov dx, COM1 + 3
    mov al, 0x80
    out dx, al          ; Enable DLAB
    
    mov dx, COM1
    mov al, 1
    out dx, al          ; Divisor low (115200 baud)
    
    mov dx, COM1 + 1
    xor al, al
    out dx, al          ; Divisor high
    
    mov dx, COM1 + 3
    mov al, 0x03
    out dx, al          ; 8N1, disable DLAB
    
    mov dx, COM1 + 2
    mov al, 0xC7
    out dx, al          ; Enable FIFO
    
    mov dx, COM1 + 4
    mov al, 0x0B
    out dx, al          ; RTS/DSR set
    ret

serial_send:            ; AL = byte to send
    push edx
    push eax
    mov dx, COM1 + 5
@@: in al, dx
    test al, 0x20
    jz @b
    pop eax
    mov dx, COM1
    out dx, al
    pop edx
    ret

serial_recv:            ; Returns byte in AL (blocking)
    push edx
    mov dx, COM1 + 5
@@: in al, dx
    test al, 1
    jz @b
    mov dx, COM1
    in al, dx
    pop edx
    ret

serial_print:           ; ESI = null-terminated string
    push eax
    push esi
@@: lodsb
    test al, al
    jz .done
    call serial_send
    jmp @b
.done:
    pop esi
    pop eax
    ret

serial_hex32:           ; EAX = value to print
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
@@: call serial_send
    pop eax
    loop .loop
    pop ecx
    pop eax
    ret