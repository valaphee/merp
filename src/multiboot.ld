MULTIBOOT_MAGIC = 0x1BADB002;
MULTIBOOT_FLAGS = 0x00010003;

//BASE = 0xC0000000;
BASE = 0;

ENTRY(_start)

SECTIONS {
    .init : {
        _load_addr = .;
        // magic (required)
        LONG(MULTIBOOT_MAGIC);
        // flags (required)
        LONG(MULTIBOOT_FLAGS);
        // checksum (required)
        LONG(-(MULTIBOOT_MAGIC + MULTIBOOT_FLAGS));
        // header_addr (present if flags[16] is set)
        LONG(_load_addr);
        // load_addr (present if flags[16] is set)
        LONG(_load_addr);
        // load_end_addr (present if flags[16] is set)
        LONG(_load_end_addr);
        // bss_end_addr (present if flags[16] is set)
        LONG(_bss_end_addr);
        // entry_addr (present if flags[16] is set)
        LONG(_start);
        *(.init)
    }

    . += BASE;

    .text ALIGN(CONSTANT(MAXPAGESIZE)) : AT(ADDR(.text) - BASE) {
        *(.text)
    }

    .rodata ALIGN(CONSTANT(MAXPAGESIZE)) : AT(ADDR(.rodata) - BASE) {
        *(.rodata)
    }

    .data ALIGN(CONSTANT(MAXPAGESIZE)) : AT(ADDR(.data) - BASE) {
        *(.data)
    }

    _load_end_addr = . - BASE;

    .bss ALIGN(CONSTANT(MAXPAGESIZE)) (NOLOAD) : AT(ADDR(.bss) - BASE) {
        *(.bss)
        *(COMMON)
    }

    _bss_end_addr = . - BASE;

    /DISCARD/ : {
        *(.eh_frame .eh_frame*)
    }
}
