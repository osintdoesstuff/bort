# bort

The world's shittiest OS



### Features



* A screen editor featuring C O L O R S .
* A nice PC speaker boot sound
* Cursor keys can move the cursor
* Caps lock support (i'm running out of things to say)
* A blue bar up top showing some state stuff
* RAM dump feature i guess?
* COM1 driver, 115200 baud 8N1
* I dunno what else to say
* PS/2 keyboards
* Exception handling
* A """API""" (a bunch of functions you can call) for vga, serial, misc stuff, and ps/2 functions
* NO memory management. Flat af YEEHAAAAAAAAAW!



### Limitations



* Once it loads the kernel it's DONE. It'll never be able to touch the disk ever again meaning no FS or nothin'
* Despite being in Protected Mode it only can use 1MB of RAM because i dunno how to GDT right
* Timer is 70hz and based on VGA frame timing
* No multitasking.



### Building



Use FASM to compile "boot.asm". Then, you get boot.img, a floppy image containing all of bort. Note includes handle all the other files



### Usage



* Ctrl+Alt+Del to clear screen and make a noise
* Ctrl+Alt+Insert to do the same thing but a DIFFERNT noise
* PgUp to make a noise
* PgDn for a different noise
* Arrow keys to move around cursor
* F1 to decrease VGA color value by one
* F2 to increase VGA color value by one
* F3 to reset VGA color
* F4 to dump RAM over serial (it takes a while, 77 seconds or so)
* F5 to toggle disco mode
* F6 to turn on high-intensity backgrounds (can't be turned off!)
* F7 to increase bar color value by one
* F8 to decrease bar color value by one
* F9 to dump register state
* Use 86box to emulate. I'd recommend a 486 or Pentium system
* You might need to use some other emulator to take a RAM dump into a file unless you can figure out 86box's serial passthrough system which i can't


### System Requirements



* At least 1MB of RAM
* VGA-compatible card
* PS/2 keyboard
* PC beeper speaker (optional)
* 486 or above CPU
* Note that Bort does not support the 286 or 8086. A 32-bit CPU is required
* Compilation: Only tested on Windows, sorry (but barely)


### Repo Contents



* All ASM files: bort source code
* exampleProg.asm: Can be used as replacement for main.asm. Demonstrates Bort's ability to run any PMode program basically, not just main.asm
* halter.asm: Another replacement for main.asm. It halts. That's it.
* README.MD: this readme
* LICENSE.MD: license
* recvm.7z: recommended 86box vm (now with pre-configured BIOS options!)
* boot.img: Compiled version (not always up-to-date!)