MULTIBOOT_MAGIC = 0x1BADB002;
MULTIBOOT_FLAGS = 0x00010003;

LOAD = 0x0000000000010000;
BASE = 0xFFFFFFFF80000000;

ENTRY(_start)

SECTIONS {
    . = LOAD;
    _load_addr = .;

    .init : {
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
        . = ALIGN(CONSTANT(MAXPAGESIZE));
    }

    . += BASE;

    .text ALIGN(CONSTANT(MAXPAGESIZE)) : AT(ADDR(.text) - BASE) {
        *(.text .text.*)
        . = ALIGN(CONSTANT(MAXPAGESIZE));
    }

    .rodata ALIGN(CONSTANT(MAXPAGESIZE)) : AT(ADDR(.rodata) - BASE) {
        *(.rodata .rodata.*)
        . = ALIGN(CONSTANT(MAXPAGESIZE));
    }

    .data ALIGN(CONSTANT(MAXPAGESIZE)) : AT(ADDR(.data) - BASE) {
        *(.data .data.*)
        . = ALIGN(CONSTANT(MAXPAGESIZE));
    }

    _load_end_addr = . - BASE;

    .bss ALIGN(CONSTANT(MAXPAGESIZE)) (NOLOAD) : AT(ADDR(.bss) - BASE) {
        *(.bss .bss.*)
        *(COMMON)
        . = ALIGN(CONSTANT(MAXPAGESIZE));
    }

    _bss_end_addr = . - BASE;

    /DISCARD/ : {
        *(.eh_frame .eh_frame*)
    }
}
