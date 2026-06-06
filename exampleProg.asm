mov al, 0x0a
call vga_set_color
call vga_clear
mov esi, testMsg
call vga_print
.loop:
   call randNum
   xor al, ah
   call vga_putchar
   mov ecx, 1
   call sleep
   jmp .loop

testMsg: db "Wow! I know stuff!", 0