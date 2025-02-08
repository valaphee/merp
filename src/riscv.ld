ENTRY(_start)

LOAD = 0x80000000;

SECTIONS {
    . = LOAD;

    .text : {
        *(.text .text.*)
    }

    .rodata : {
        *(.rodata .rodata.*)
    }

    .data : {
        *(.data .data.*)
    }

    .bss (NOLOAD) : {
        *(.bss .bbs.*)
    }
}
