MULTIBOOT_MAGIC = 0x1BADB002;
MULTIBOOT_FLAGS = 0x00010003;

LOAD = 0x0000000000100000;
BASE = 0xFFFFFFFF80000000;

ENTRY(_start)

SECTIONS {
    . = LOAD;

    .init : {
        // magic (required)
        LONG(MULTIBOOT_MAGIC);
        // flags (required)
        LONG(MULTIBOOT_FLAGS);
        // checksum (required)
        LONG(-(MULTIBOOT_MAGIC + MULTIBOOT_FLAGS));
        // header_addr (present if flags[16] is set)
        LONG(LOAD);
        // load_addr (present if flags[16] is set)
        LONG(LOAD);
        // load_end_addr (present if flags[16] is set)
        LONG(__bss - BASE);
        // bss_end_addr (present if flags[16] is set)
        LONG(__bss_end - BASE);
        // entry_addr (present if flags[16] is set)
        LONG(_start);
        *(.init)
    }

    . += BASE;

    .text ALIGN(CONSTANT(MAXPAGESIZE)) : AT(ADDR(.text) - BASE) {
        __text = .;
        *(.text .text.*)
        __text_end = .;
    }

    .rodata ALIGN(CONSTANT(MAXPAGESIZE)) : AT(ADDR(.rodata) - BASE) {
        __rodata = .;
        *(.rodata .rodata.*)
        __rodata_end = .;
    }

    .data ALIGN(CONSTANT(MAXPAGESIZE)) : AT(ADDR(.data) - BASE) {
        __data = .;
        *(.data .data.*)
        __data_end = .;
    }

    .bss ALIGN(CONSTANT(MAXPAGESIZE)) (NOLOAD) : AT(ADDR(.bss) - BASE) {
        __bss = .;
        *(.bss .bss.*)
        *(COMMON)
        __bss_end = .;
    }

    /DISCARD/ : {
        *(.eh_frame .eh_frame*)
    }
}
