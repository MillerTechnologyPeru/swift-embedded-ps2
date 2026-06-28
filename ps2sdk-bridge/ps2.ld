/*
 * ps2.ld — Linker script for PS2 EE ELF (MIPS-II, O32 ABI, ELF32)
 *
 * EE user RAM: 32 MB (0x00000000 – 0x01FFFFFF)
 * Standard homebrew ELF load address: 0x00100000
 * Stack pointer set to 0x01FF0000 in boot_mips.S (grows downward).
 *
 * PCSX2 loads the ELF via the entry address in the ELF header and
 * jumps to _start. No separate header wrapper needed (unlike .psexe).
 */

OUTPUT_ARCH(mips)
ENTRY(_start)

MEMORY {
    RAM (rwx) : ORIGIN = 0x00100000, LENGTH = 0x00EF0000   /* ~15 MB usable */
}

SECTIONS {
    . = 0x00100000;

    .text : {
        KEEP(*(.text.boot))     /* _start must be the first byte */
        *(.text*)
        *(.rodata*)
    } > RAM

    .data : {
        *(.data*)
    } > RAM

    /* GP anchor: _gp = GOT_start + 0x7FF0, covers .sdata/.sbss within ±32 KB */
    .got : {
        *(.got*)
    } > RAM

    .sdata : {
        *(.sdata*)
    } > RAM

    .sbss (NOLOAD) : {
        _bss_start = .;
        *(.sbss*)
        *(COMMON)
    } > RAM

    .bss (NOLOAD) : {
        *(.bss*)
        . = ALIGN(8);    /* ensure _bss_end is 8-byte aligned for boot sd loop */
        _bss_end = .;
    } > RAM

    /* Heap starts here (used by sbrk_ee in shim_mips.c) */
    _end = .;

    /DISCARD/ : {
        *(.eh_frame*)
        *(.ARM.exidx*)
        *(.comment)
        *(.note*)
        *(.MIPS.abiflags)
        *(.mdebug*)      /* MIPS debug info — address 0x0 confuses PS2 BIOS ELF loader */
        *(.pdr)          /* procedure debug records — same issue */
        *(.reginfo)
    }
}
