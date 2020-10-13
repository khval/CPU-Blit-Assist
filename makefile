# Makefile for CPU_Blitting_Assist
#
# Author: Jeroen Knoester
# Version 1.0
# Revision: 20200208

# Setup required suffixes for make
.SUFFIXES: .asm .o

# Setup executable name
EXECUTABLE=CPU_Blit_Assist

# Setup where executables should be installed
INSTLOC=D:\Development\AmigaEnvironment\AmigaTransfer

# Setup assembler & linker
ASM=vasmm68k_mot
LNK=vlink

# Setup includes & libraries
INCLUDE=-I$(MAINDIR) -I$(SYSTEMDIR) -I$(GFXDIR) -I$(SUPPORTDIR) -I$(DATADIR)
LIBS=-L $(MAINDIR)\..\LIB -l amiga

# Setup assembler flags
ASMFLAGS_STD=$(INCLUDE) -nowarn=62 -kick1hunks -Fhunk -m68020 -allmp
ASMFLAGS=$(ASMFLAGS_STD)
ASMFLAGS_STARTUP=$(INCLUDE) -no-opt -nowarn=62 -kick1hunks -Fhunk -m68020 -allmp

# Setup linker flags
LNKFLAGS=$(LIBS) -bamigahunk -s -Z

# Setup include directories
MAINDIR=.
GFXDIR=$(MAINDIR)\GFX
DATADIR=$(MAINDIR)\Data
STARTUPDIR=$(MAINDIR)\Startup
SUPPORTDIR=$(MAINDIR)\Support
SYSTEMDIR=$(MAINDIR)\..\INCLUDE13

# Objects
GFX=$(GFXDIR)\blitter.o $(GFXDIR)\cpublit.o $(GFXDIR)\comboblit.o $(GFXDIR)\tilemap.o $(GFXDIR)\font.o $(GFXDIR)\object.o
DATA=$(DATADIR)\copperlists.o $(DATADIR)\tiles.o $(DATADIR)\bobs.o $(DATADIR)\background.o
STARTUP=$(STARTUPDIR)\PhotonsMiniWrapper.o
SUPPORT=$(SUPPORTDIR)\performance.o $(SUPPORTDIR)\titletext.o
MAIN=$(MAINDIR)\CPU_Blit_Assist.o

# Targets
all: $(EXECUTABLE)

install: $(EXECUTABLE)
	copy /Y $(EXECUTABLE) $(INSTLOC)\$(EXECUTABLE)

clean:
	del /Q /F $(MAINDIR)\$(EXECUTABLE) $(MAINDIR)\*.o $(GFXDIR)\*.o $(STARTUPDIR)\*.o $(DATADIR)\*.o $(SUPPORTDIR)\*.o

show_depend: ASMFLAGS=$(ASMFLAGS_STD) -depend=make -quiet
show_depend: all

$(EXECUTABLE): $(MAIN) $(GFX) $(STARTUP) $(SUPPORT) $(DATA)
	$(LNK) $(LNKFLAGS) $(STARTUP) $(MAIN) $(GFX) $(SUPPORT) $(DATA) -o $@

# Assemble objects
$(MAINDIR)\CPU_Blit_Assist.o: $(MAINDIR)\CPU_Blit_Assist.asm Support\debug.i CPU_Blit_Assist.i GFX\blitter.i GFX\cpublit.i GFX\displaybuffers.i Data\copperlists.i Data\bobs.i GFX\font.i Data\background.i GFX\object.i GFX\tilemap.i Support\performance.i Support\titletext.i Support\cia_timer.i
	$(ASM) $(ASMFLAGS) $< -o $@
$(GFXDIR)\blitter.o: $(GFXDIR)\blitter.asm Support\debug.i GFX\blitter.i GFX\tilemap.i GFX\displaybuffers.i Data\bobs.i
	$(ASM) $(ASMFLAGS) $< -o $@
$(GFXDIR)\cpublit.o: $(GFXDIR)\cpublit.asm Support\debug.i GFX\blitter.i GFX\cpublit.i GFX\object.i GFX\tilemap.i GFX\displaybuffers.i Data\bobs.i
	$(ASM) $(ASMFLAGS) $< -o $@
$(GFXDIR)\comboblit.o: $(GFXDIR)\comboblit.asm Support\debug.i GFX\object.i GFX\blitter.i GFX\comboblit.i GFX\displaybuffers.i
	$(ASM) $(ASMFLAGS) $< -o $@
$(GFXDIR)\tilemap.o: $(GFXDIR)\tilemap.asm Support\debug.i GFX\displaybuffers.i GFX\blitter.i Data\tiles.i GFX\tilemap.i
	$(ASM) $(ASMFLAGS) $< -o $@
$(GFXDIR)\font.o: $(GFXDIR)\font.asm Support\debug.i GFX\font.i
	$(ASM) $(ASMFLAGS) $< -o $@
$(GFXDIR)\object.o: $(GFXDIR)\object.asm GFX\object.i Support\debug.i
	$(ASM) $(ASMFLAGS) $< -o $@
$(SUPPORTDIR)\performance.o: $(SUPPORTDIR)\performance.asm GFX\blitter.i GFX\comboblit.i GFX\object.i Support\performance.i Support\debug.i Support\cia_timer.i
	$(ASM) $(ASMFLAGS) $< -o $@
$(DATADIR)\copperlists.o: $(DATADIR)\copperlists.asm GFX\displaybuffers.i Data\copperlists.i
	$(ASM) $(ASMFLAGS) $< -o $@
$(DATADIR)\tiles.o: $(DATADIR)\tiles.asm Data\tiles.i data\sb_tiles_raw
	$(ASM) $(ASMFLAGS) $< -o $@
$(DATADIR)\background.o: $(DATADIR)\background.asm Data\background.i data\background_6bpl_raw
	$(ASM) $(ASMFLAGS) $< -o $@
$(DATADIR)\bobs.o: $(DATADIR)\bobs.asm Data\bobs.i data\bob_6bpl_raw data\mask_6bpl_raw
	$(ASM) $(ASMFLAGS) $< -o $@
$(SUPPORTDIR)\titletext.o: $(SUPPORTDIR)\titletext.asm Support\titletext.i
	$(ASM) $(ASMFLAGS) $< -o $@
	
$(STARTUPDIR)\PhotonsMiniWrapper.o: $(STARTUPDIR)\PhotonsMiniWrapper.asm
	$(ASM) $(ASMFLAGS_STARTUP) $< -o $@