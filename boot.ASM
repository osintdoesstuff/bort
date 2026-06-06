format binary as "img"

org 0x7C00
use16
jmp start
time: dw 0

start:
    ; Set up segments
    xor ax, ax
    mov ds, ax
    mov es, ax
    mov ss, ax
    mov sp, 0x7C00
    
    ; Print loading message
    mov si, msg_loading
    call print_real

    ; Load sectors to 0x7E00
    mov bx, 0x7E00      ; destination
    mov al, 17          ; sectors to read 
    mov ch, 0           ; cylinder 0
    mov cl, 2           ; start from sector 2
    mov dh, 0           ; head 0
    mov dl, 0
    call load_sectors
    
    ; MOAR SECTORS
    mov bx, 0xA000
    mov al, 18
    mov ch, 1
    mov cl, 1
    call load_sectors
    
    mov bx, 0xC400
    mov ch, 2
    call load_sectors
    
    mov bx, 0xE800
    mov al, 12          ; as much as this segment can fucking fit
    mov ch, 3
    call load_sectors
    
    call getTbRseed
    
    ; Print success
    mov si, msg_ok
    call print_real

    ; NOW do protected mode switch
    cli
    call enable_a20
    lgdt [gdt_descriptor]
    
    mov eax, cr0
    or al, 1
    mov cr0, eax
    
    jmp 0x08:protected_mode

; Load sectors from floppy
load_sectors:
    mov ah, 0x02        ; BIOS read sectors function
    mov di, 3
.retry:
    push ax
    push bx
    push cx
    push dx
    
    int 0x13
    jnc .success        ; CF clear = success
    
    xor ax, ax
    int 0x13
    
    pop dx
    pop cx
    pop bx
    pop ax
    
    dec di
    jnz .retry
    
    mov si, msg_fail
    call print_real
    jmp $

.success:
    pop dx
    pop cx
    pop bx
    pop ax
    ret

print_real:
    lodsb
    test al, al
    jz .done
    mov ah, 0x0E
    int 0x10
    jmp print_real
.done:
    ret

getTbRseed:
    push ax
    push cx
    push dx
    xor ax, ax
    int 1Ah
    xor cx, dx
    mov [time], cx
    pop dx
    pop cx
    pop ax
    ret

align 16
gdt:
.null:
    dq 0
.code:
    dw 0xFFFF       ; limit low
    dw 0x0000       ; base low
    db 0x00         ; base middle
    db 10011010b    ; access
    db 11001111b    ; flags + limit high
    db 0x00         ; base high
.data:
    dw 0xFFFF
    dw 0x0000
    db 0x00
    db 10010010b
    db 11001111b
    db 0x00
.end:

gdt_descriptor:
    dw gdt.end - gdt - 1
    dd gdt          ; FASM will calculate this correctly with 'org 0x7C00'

enable_a20:
    call .check
    jz .done          ; Already enabled

    mov ax, 0x2401
    int 0x15
    call .check
    jz .done

    call .wait_cmd
    mov al, 0xD1
    out 0x64, al
    call .wait_cmd
    mov al, 0xDF
    out 0x60, al
    call .wait_cmd

    in al, 0x92
    or al, 2
    and al, 0xFE      ; Don't reset!
    out 0x92, al
.done:
    ret

.check:
    pushad
    mov edi, 0x112345
    mov esi, 0x012345
    mov [esi], esi
    mov [edi], edi
    cmpsd
    popad
    ret

.wait_cmd:
    in al, 0x64
    test al, 2
    jnz .wait_cmd
    ret

msg_loading db "Borting...", 13, 10, 0
msg_ok db "Borting completed successfully!", 13, 10, 0
msg_fail db "Disk sad :C", 0
msg db "386ing...", 13, 10, 0

times 510-($-$$) db 0
dw 0xAA55

org 0x7e00 
use32

protected_mode:
    mov ax, 0x10
    mov ds, ax
    mov es, ax
    mov ss, ax
    mov fs, ax
    mov gs, ax
    
                                                           

    lidt [idt_descriptor]
    ; int 3 ; debug breakpoint!
    jmp mainStart


macro idt_gate handler_address {
    dw (handler_address and 0FFFFh)
    dw 0x08 ; code selector
    db 0
    db 10001110b ; attributes
    dw ((handler_address shr 16) and 0FFFFh)
}

macro ISR_NOERRCODE num {
    isr_handler_#num:
        cli
        push 0
        push num
        jmp common_exception_handler
}
macro ISR_ERRCODE num {
    isr_handler_#num:
        cli
        push num
        jmp common_exception_handler
}

align 4
idt_start:
    idt_gate isr_handler_0
    idt_gate isr_handler_1
    idt_gate isr_handler_2
    idt_gate isr_handler_3
    idt_gate isr_handler_4
    idt_gate isr_handler_5
    idt_gate isr_handler_6
    idt_gate isr_handler_7
    idt_gate isr_handler_8
    idt_gate isr_handler_9
    idt_gate isr_handler_10
    idt_gate isr_handler_11
    idt_gate isr_handler_12
    idt_gate isr_handler_13
    idt_gate isr_handler_14
    idt_gate isr_handler_15
    idt_gate isr_handler_16
    idt_gate isr_handler_17
    idt_gate isr_handler_18
    idt_gate isr_handler_19
    idt_gate isr_handler_20
    idt_gate isr_handler_21
    idt_gate isr_handler_22
    idt_gate isr_handler_23
    idt_gate isr_handler_24
    idt_gate isr_handler_25
    idt_gate isr_handler_26
    idt_gate isr_handler_27
    idt_gate isr_handler_28
    idt_gate isr_handler_29
    idt_gate isr_handler_30
    idt_gate isr_handler_31
idt_end:

idt_descriptor:
    dw idt_end - idt_start - 1
    dd idt_start
ISR_NOERRCODE 0
ISR_NOERRCODE 1
ISR_NOERRCODE 2
ISR_NOERRCODE 3
ISR_NOERRCODE 4
ISR_NOERRCODE 5
ISR_NOERRCODE 6
ISR_NOERRCODE 7
ISR_ERRCODE   8
ISR_NOERRCODE 9
ISR_ERRCODE   10
ISR_ERRCODE   11
ISR_ERRCODE   12
ISR_ERRCODE   13
ISR_ERRCODE   14
ISR_NOERRCODE 15
ISR_NOERRCODE 16
ISR_ERRCODE   17
ISR_NOERRCODE 18
ISR_NOERRCODE 19
ISR_NOERRCODE 20
ISR_ERRCODE   21
ISR_NOERRCODE 22
ISR_NOERRCODE 23
ISR_NOERRCODE 24
ISR_NOERRCODE 25
ISR_NOERRCODE 26
ISR_NOERRCODE 27
ISR_NOERRCODE 28
ISR_NOERRCODE 29
ISR_ERRCODE   30
ISR_NOERRCODE 31

mainStart:
include "main.asm"
;include "exampleProg.asm"
;include "halter.asm"
include "serial.asm"
include "vga.asm"
include "ps2kbd.asm"
include "misc.asm"

times 1474048-($-$$) db 0 ; keep FASM output 1.44MB