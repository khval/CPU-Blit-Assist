# Preface

This repository is aims as being test case for chipset.libary, but while I work on it I realized changes I made to make it compile on Amiga systems can be useful for beginners, there for the project is spited into two.

Repository “Lacey” for classic Amiga systems.

Repository “Main” for chipset.libary (Systems without Amiga chipset AmigaONE,Amitalon,Dracro)

Repository will be merged when its all done, compiler switches allow 
you to compile for chipset.library or use bang the hardware directly.

I should maybe end with small disclaimer this I only bowered the code, read copyright noticed at bottom. Sadly, they did use git.

**Best Regards**
Kjetil Hvalstrand

# CPU Blit Assist readme

CPU Blit Assist is an example program that showcases an easy to implement
method for blitting bobs using the CPU and Blitter in combination. This
increases blitting performance on AGA machines. The code is primarily aimed 
at the low end AGA machines, the A1200 and CD32*.

The example shows how concurrent Blitter+CPU blitting can improve blitting
performance by around 13%. Which is not an amazing number by itself, but it
is essentially "free": other than the code itself and a requirement for using
only bob image data that is aligned to 32 bit boundaries and is multiples of
32 bits wide, there are no extra costs in terms of memory. As a result, 
memory use for 32 pixel wide bobs is identical to that of normal interleaved
bobs.

Relative performance of this effect increases as fetching speed is reduced, 
as long as the bus is not fully saturated (i.e. 8 bitplanes lowres/1x fetch).

*) The algorithm will also work on all other machines with 32-bit chip memory
   and at least a 68020 (i.e. the A3000/A4000). However, normally such 
   machines have fast memory and faster processors. Such machines are better
   served by using algorithms that rely on fast memory instead, as this will 
   be much faster.

**) This is the result of the example program on a real PAL A1200. Note that
    the program uses a routine optimized for 32 bit wide bobs, blitting 
    objects of different widths with the supplied routines for wider bobs 
    might result in a slightly different performance gain. The routines for 
    wider bobs are currently less optimal, perhaps they can be further 
    optimized for better results.

The progam is intended to show how to achieve this effect and as such, the 
full source code in 68020 assembly is included, as well as all source data 
used.


More information about the effect, method, performance, etc can be found on 
my website: http://www.powerprograms.nl/amiga/cpu-blit-assist.html

Copyright notice:

All code, apart from the startup code, joystick reading code and random 
number generator was written by me and is (C) 2020, Jeroen Knoester. Startup
Code by Photon of Scoopex. Joystick reading code as found on the English 
Amiga Board. Random number generator by Meynaf from the English Amiga Board.


That said, please do use any part of my code or this idea you find useful. A
credit/mention would be nice, but is not required in any way.
