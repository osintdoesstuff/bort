pmode_sectory:
   call bootSound
   ; don't ask me why, this just happened to be the method that worked!
   push ax
   mov ax, [time]
   mov [rSeed], ax
   pop ax
   in al, 0x60         ; Read and discard
   in al, 0x60         ; Read and discard again
   call reset_registers
   call serial_init
   call reset_registers
   call reset_registers
   mov al, 0x0A
   call vga_set_color
   call vga_clear
   call draw_titlebar
   mov byte [vga_cursor_y], 1
   call vga_update_cursor

.loop:
    ; Disco check BEFORE waiting for input
    cmp byte [disco_mode], 1
    jne .no_disco
    push eax
    call randNum
    xor ah, al
    mov [vga_color], ah
    pop eax
    call draw_titlebar
    .no_disco:

    call kb_getchar
    test al, al
    jz .loop
    
    ; Check for arrow keys (our custom codes)
    cmp al, 0x01
    je .handle_up
    cmp al, 0x02
    je .handle_down
    cmp al, 0x03
    je .handle_left
    cmp al, 0x04
    je .handle_right
    
    ; Normal character
    call vga_putchar
    call draw_titlebar ; redraw bort
    add [rSeed], 12345
    jmp .loop

.handle_up:
    cmp byte [vga_cursor_y], 1
    je .loop
    dec byte [vga_cursor_y]
    call vga_update_cursor
    jmp .loop

.handle_down:
    cmp byte [vga_cursor_y], 24 ; VGA_HEIGHT - 1
    je .loop
    inc byte [vga_cursor_y]
    call vga_update_cursor
    jmp .loop

.handle_left:
    cmp byte [vga_cursor_x], 0
    je .loop
    dec byte [vga_cursor_x]
    call vga_update_cursor
    jmp .loop

.handle_right:
    cmp byte [vga_cursor_x], 79 ; VGA_WIDTH - 1
    je .loop
    inc byte [vga_cursor_x]
    call vga_update_cursor
    jmp .loop