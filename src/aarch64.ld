OUTPUT_FORMAT(binary)
ENTRY(_start)

LOAD = 0x00080000;

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
        *(COMMON)
    }
}
