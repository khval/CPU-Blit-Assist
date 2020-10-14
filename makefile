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
INSTLOC=RAM:

# Setup assembler & linker
ASM=os4_cross_compiler_vasmm68k_mot
LNK=vlink

# Setup includes & libraries
INCLUDE= -I$(SYSTEMDIR) -I$(GFXDIR) -I$(SUPPORTDIR) -I$(DATADIR)
LIBS=-L $(MAINDIR)/../LIB -l amiga

# Setup assembler flags
ASMFLAGS_STD=$(INCLUDE) -Fhunk -m68020 
ASMFLAGS=$(ASMFLAGS_STD)
ASMFLAGS_STARTUP=$(INCLUDE) -no-opt -nowarn=62 -kick1hunks -Fhunk -m68020 -allmp

# Setup linker flags
LNKFLAGS=$(LIBS) -bamigahunk -s 

# Setup include directories
MAINDIR=
GFXDIR=$(MAINDIR)GFX/
DATADIR=$(MAINDIR)Data/
STARTUPDIR=$(MAINDIR)Startup/
SUPPORTDIR=$(MAINDIR)Support/
SYSTEMDIR=sdk31:

# Objects
GFX=$(GFXDIR)blitter.o $(GFXDIR)cpublit.o $(GFXDIR)comboblit.o $(GFXDIR)tilemap.o $(GFXDIR)font.o $(GFXDIR)object.o
DATA=$(DATADIR)copperlists.o $(DATADIR)tiles.o $(DATADIR)bobs.o $(DATADIR)background.o
STARTUP=$(STARTUPDIR)PhotonsMiniWrapper.o
SUPPORT=$(SUPPORTDIR)performance.o $(SUPPORTDIR)titletext.o
MAIN=$(MAINDIR)CPU_Blit_Assist.o

# Targets
all: $(EXECUTABLE)

install: $(EXECUTABLE)
	copy  $(EXECUTABLE) $(INSTLOC)$(EXECUTABLE)

clean:
	delete $(MAINDIR)$(EXECUTABLE) $(MAINDIR)#?.o $(GFXDIR)#?.o $(STARTUPDIR)#?.o $(DATADIR)#?.o $(SUPPORTDIR)#?.o

show_depend: ASMFLAGS=$(ASMFLAGS_STD) -depend=make -quiet
show_depend: all

$(EXECUTABLE): $(MAIN) $(GFX) $(STARTUP) $(SUPPORT) $(DATA)
	$(LNK) $(LNKFLAGS) $(STARTUP) $(MAIN) $(GFX) $(SUPPORT) $(DATA) -o $@

# Assemble objects
$(MAINDIR)CPU_Blit_Assist.o: $(MAINDIR)CPU_Blit_Assist.asm $(SUPPORTDIR)debug.i CPU_Blit_Assist.i $(GFXDIR)blitter.i $(GFXDIR)cpublit.i $(GFXDIR)displaybuffers.i Data/copperlists.i Data/bobs.i $(GFXDIR)font.i Data/background.i $(GFXDIR)object.i $(GFXDIR)tilemap.i Support/performance.i Support/titletext.i Support/cia_timer.i
	$(ASM) $(ASMFLAGS) $< -o $@
$(GFXDIR)blitter.o: $(GFXDIR)blitter.asm $(SUPPORTDIR)debug.i $(GFXDIR)blitter.i $(GFXDIR)tilemap.i $(GFXDIR)displaybuffers.i Data/bobs.i
	$(ASM) $(ASMFLAGS) $< -o $@
$(GFXDIR)cpublit.o: $(GFXDIR)cpublit.asm $(SUPPORTDIR)debug.i $(GFXDIR)blitter.i $(GFXDIR)cpublit.i $(GFXDIR)object.i $(GFXDIR)tilemap.i $(GFXDIR)displaybuffers.i Data/bobs.i
	$(ASM) $(ASMFLAGS) $< -o $@
$(GFXDIR)comboblit.o: $(GFXDIR)comboblit.asm $(SUPPORTDIR)debug.i $(GFXDIR)object.i $(GFXDIR)blitter.i $(GFXDIR)comboblit.i $(GFXDIR)displaybuffers.i
	$(ASM) $(ASMFLAGS) $< -o $@
$(GFXDIR)tilemap.o: $(GFXDIR)tilemap.asm $(SUPPORTDIR)debug.i $(GFXDIR)displaybuffers.i $(GFXDIR)blitter.i Data/tiles.i $(GFXDIR)tilemap.i
	$(ASM) $(ASMFLAGS) $< -o $@
$(GFXDIR)font.o: $(GFXDIR)font.asm $(SUPPORTDIR)debug.i $(GFXDIR)font.i
	$(ASM) $(ASMFLAGS) $< -o $@
$(GFXDIR)object.o: $(GFXDIR)object.asm $(GFXDIR)object.i $(SUPPORTDIR)debug.i
	$(ASM) $(ASMFLAGS) $< -o $@
$(SUPPORTDIR)performance.o: $(SUPPORTDIR)performance.asm $(GFXDIR)blitter.i $(GFXDIR)comboblit.i $(GFXDIR)object.i $(SUPPORTDIR)performance.i $(SUPPORTDIR)debug.i $(SUPPORTDIR)cia_timer.i
	$(ASM) $(ASMFLAGS) $< -o $@
$(DATADIR)copperlists.o: $(DATADIR)copperlists.asm $(GFXDIR)displaybuffers.i Data/copperlists.i
	$(ASM) $(ASMFLAGS) $< -o $@
$(DATADIR)tiles.o: $(DATADIR)tiles.asm Data/tiles.i data/sb_tiles_raw
	$(ASM) $(ASMFLAGS) $< -o $@
$(DATADIR)background.o: $(DATADIR)background.asm Data/background.i data/background_6bpl_raw
	$(ASM) $(ASMFLAGS) $< -o $@
$(DATADIR)bobs.o: $(DATADIR)bobs.asm Data/bobs.i data/bob_6bpl_raw data/mask_6bpl_raw
	$(ASM) $(ASMFLAGS) $< -o $@
$(SUPPORTDIR)titletext.o: $(SUPPORTDIR)titletext.asm $(SUPPORTDIR)titletext.i
	$(ASM) $(ASMFLAGS) $< -o $@
	
$(STARTUPDIR)PhotonsMiniWrapper.o: $(STARTUPDIR)PhotonsMiniWrapper.asm
	$(ASM) $(ASMFLAGS_STARTUP) $< -o $@