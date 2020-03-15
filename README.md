XmasFree is a game prototype made for the Sega Genesis and inspired by the Windows game SkiFree. The prototype is very rough but I wanted to make it available to anyone who might be interested in making their own Sega Genesis games using 68k ASM. The final version of the game was renamed to MegaXmas'89, and has since been released here https://nekojitagames.itch.io/megaxmas89

This project is based on the Mega Drive samples from Matt Phillips found here https://github.com/BigEvilCorporation/megadrive_samples

----------------------------------
Setup
----------------------------------
1) Install DosBox https://www.dosbox.com/
2) Place the following files in the directory external/echo from Sik's Echo Sound Engine project https://github.com/sikthehedgehog/Echo
- echo.68k https://github.com/sikthehedgehog/Echo/blob/master/src-68k/echo.68k
- prog-z80.bin https://github.com/sikthehedgehog/Echo/blob/master/built/prog-z80.bin
3) Find this line in echo.68k
   @Z80Program: incbin "../bin/prog-z80.bin"
   and replace it with 
   @Z80Program: incbin "external/echo/prog-z80.bin"

----------------------------------
Build
----------------------------------
Windows - Run build.cmd
Mac/Linux - Run build.sh
Output is found in te build directory.