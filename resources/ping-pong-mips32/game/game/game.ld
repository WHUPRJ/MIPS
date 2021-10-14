ENTRY(INITLOCATE)
OUTPUT("game.elf")
OUTPUT_ARCH("mips:isa32r2")
OUTPUT_FORMAT("elf32-tradlittlemips")

SECTIONS
{
    . = 0x807F0000;
    .bss : {
        _sbss = .;
        *(.bss)
        . = ALIGN(4);
        _ebss = .;
    }
    . = 0x80000000;
    .text : {
        *(.text.init)
        . = 0x1000;
        _text_ebase_begin = .;
        *(.text.ebase)
        . = 0x1180;
        *(.text.ebase180)
        _text_ebase_end = .;
        . = ALIGN(0x1000);
        _text_code_begin = .;
        *(.text)
        . = ALIGN(0x1000);
        _text_code_end = .;
    }
    _data_begin = .;
    .rodata : {
        *(.rodata)
        . = ALIGN(4);
    }
    .data : {
        *(.data)
        . = ALIGN(4);
    }
    _data_end = .;
}
