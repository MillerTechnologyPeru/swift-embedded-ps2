# boot_mips.S — PS2 EE bare-metal entry point (MIPS-II, O32 ABI, ELF32)
#
# The PS2 EE kernel loads the ELF and jumps to _start.
# Mirrors the prussia project's boot approach:
#   1. Set $sp in the delay slot of the jump to C entry
#   2. In _start: set $gp, zero .bss (4-byte stores), call swift_main
#
# EE user RAM: 32 MB (0x00000000 – 0x01FFFFFF)
# Stack at 0x01FF0000 (grows downward, well above our binary at 0x100000)

    .section .text.boot, "ax", @progbits
    .set    mips2
    .set    noreorder
    .global _start
    .type   _start, @function

_start:
    # Set stack pointer to near top of EE user RAM, init $gp, zero BSS.
    lui     $sp, 0x01FF         # $sp = 0x01FF0000
    addiu   $sp, $sp, -8        # O32 8-byte stack alignment

    .set    reorder
    la      $gp, _gp
    .set    noreorder

    # Zero .bss 4 bytes at a time.  _bss_end is ALIGN(8) so the loop terminates.
    la      $t0, _bss_start
    la      $t1, _bss_end
.zero_bss:
    beq     $t0, $t1, .call_swift
    nop
    sw      $zero, 0($t0)
    addiu   $t0, $t0, 4
    j       .zero_bss
    nop

.call_swift:
    # $t9 must hold the callee address for O32 ABI position-independent calls.
    .set    reorder
    la      $t9, swift_main
    jalr    $t9
    .set    noreorder
    nop

.halt:
    j       .halt
    nop

    .size _start, . - _start
