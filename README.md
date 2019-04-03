# DiskSectorReader
Functions developed to read sectors of a disk image as a part of the Systems Programming module during my 3rd year at the University of Derby.

![Runtime Screenshot](https://github.com/Hesketh/BootDiskSectorReader/blob/master/Screenshot.png?raw=true)

## Functions

### Console Read Sector
The main component of the assignment, it requests input from the User using the keyboard about which sector number to start at and how many consecutive sectors to display. For example you may start at sector 12 and read 20 sectors after this.

Displaying a sector involves printing the offset from the boot image, then the hex value of all the bytes leading up to where the next offset would begin. Then finally printing the Ascii character value of all these bytes on the right. Some characters have been choosen to be replaced with "_" as their actual Ascii value is more technical and not visible (such as 7 being an audible signal).

### Console Read Integer
The user is asked to enter an integer value using the keyboard which is read and stored in the BX register. 

### Console Write CRLF
Outputs the carriage return and line feed characters so that the cursor moves to the start of the next line.

### Console Write 16
Outputs a null terminated string pointed to by the SI register to the console. 

### Console WriteLine 16
Writes a null terminated string pointed to by the SI register to the console and then outputs the carriage return and line feed to the console. 

### Console Write Integer
Displays the contents of the BX register as an unsigned decimal value.

### Console Write Hex
Displays the contents of the BX register as a hexidecimal value.
