RM	:= rm -f
ifeq ($(OS),Windows_NT)
GCCPREFIX	?= mips-mti-elf-
else
GCCPREFIX	:= mipsel-linux-gnu-
endif
QEMU        := qemu-system-mipsel
LD	        := $(GCCPREFIX)ld
CC	        := $(GCCPREFIX)gcc
MODULE	    := init
OBJDIR	    := obj
INCLUDE	    := include
SRCDIR	    := game
LDSCRIPT	:= $(SRCDIR)/game.ld
SRC	        := $(foreach sdir, $(SRCDIR), $(wildcard $(sdir)/*.S))
OBJ	        := $(patsubst $(SRCDIR)/%.S, $(OBJDIR)/%.o, $(SRC))
TARGET	    := $(OBJDIR)/game.elf
ASFLAG	    := -D__ASSEMBLY__ -EL -g -mips32r2 -mno-abicalls -mno-shared -O3

.PHONY: all clean checkdirs generate sim

all: $(TARGET) game.bin generate

$(TARGET): checkdirs $(OBJ) $(LDSCRIPT)
	$(LD) $(OBJ) -T$(LDSCRIPT) -o $(OBJDIR)/game.elf

$(OBJ): $(OBJDIR)/%.o : $(SRCDIR)/%.S
	$(CC) -o $@ $< -c -I$(INCLUDE) $(ASFLAG)

checkdirs: $(OBJDIR)

$(OBJDIR):
	test -d $@ || mkdir $@

game.bin: $(TARGET)
	@$(GCCPREFIX)objcopy -j .text -j .rodata -j .data -O binary -v $< $(OBJDIR)/game.bin
	@$(GCCPREFIX)objdump -lD $< > $(OBJDIR)/game.s

generate: game.bin convert
	./convert game.bin $(OBJDIR)/

convert: convert.c
	gcc -o convert convert.c

sim: $(TARGET)
	$(QEMU) -M mipssim -m 8M -kernel $< -nographic -monitor none -serial tcp::6666,server -s

clean:
	-$(RM) -r $(OBJDIR)
	-$(RM) convert
