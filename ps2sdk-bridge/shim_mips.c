// shim_mips.c — PS2 EE host stubs for libswiftEmbeddedPlatformPOSIX (mipsel)
//
// No ps2sdk required. Uses PS2 EE kernel syscalls directly.
// Soft-float: mipsel O32 ABI; float builtins come from PSn00bSDK libc.a.
// Provides: POSIX stubs, ps2_print, ps2_gs_init, ps2_gs_flip.

#include <stddef.h>
#include <stdint.h>

// ---------------------------------------------------------------------------
// Heap — simple arena allocator using EE RAM after _end
// ---------------------------------------------------------------------------

extern char _end[];
static char *heap_ptr = 0;

static void *sbrk_ee(size_t n) {
    if (!heap_ptr) heap_ptr = _end;
    void *p = heap_ptr;
    heap_ptr += (n + 3) & ~(size_t)3;  // 4-byte align for O32
    return p;
}

// ---------------------------------------------------------------------------
// POSIX stubs for libswiftEmbeddedPlatformPOSIX
// ---------------------------------------------------------------------------

int posix_memalign(void **memptr, size_t alignment, size_t size) {
    char *p = (char *)sbrk_ee(size + alignment);
    uintptr_t addr = (uintptr_t)p;
    addr = (addr + alignment - 1) & ~(alignment - 1);
    *memptr = (void *)addr;
    return 0;
}

void *malloc(size_t size) {
    void *p;
    posix_memalign(&p, 4, size);
    return p;
}

void free(void *ptr) { (void)ptr; }

void arc4random_buf(void *buf, size_t nbytes) {
    static uint32_t state = 0xDEADBEEF;
    uint8_t *p = (uint8_t *)buf;
    for (size_t i = 0; i < nbytes; i++) {
        state = state * 1664525u + 1013904223u;
        p[i] = (uint8_t)(state >> 24);
    }
}

// ---------------------------------------------------------------------------
// C library stubs
// ---------------------------------------------------------------------------

void *memset(void *s, int c, size_t n) {
    unsigned char *p = (unsigned char *)s;
    while (n--) *p++ = (unsigned char)c;
    return s;
}

void *memcpy(void *dst, const void *src, size_t n) {
    unsigned char *d = (unsigned char *)dst;
    const unsigned char *s = (const unsigned char *)src;
    while (n--) *d++ = *s++;
    return dst;
}

// PS2 EE kernel write syscall (number 4)
static int ee_write(int fd, const void *buf, unsigned int len) {
    register long      v0 __asm__("$2") = 4;
    register long      a0 __asm__("$4") = fd;
    register const void *a1 __asm__("$5") = buf;
    register unsigned  a2 __asm__("$6") = len;
    __asm__ volatile("syscall" : "+r"(v0) : "r"(a0), "r"(a1), "r"(a2) : "$8", "memory");
    return (int)v0;
}

int putchar(int c) {
    char ch = (char)c;
    ee_write(1, &ch, 1);
    return c;
}

void exit(int code) { (void)code; while (1) {} }

uintptr_t __stack_chk_guard = 0xDEADC0DEU;
void __stack_chk_fail(void) { while (1) {} }

// ---------------------------------------------------------------------------
// ps2_print — called from Swift
// ---------------------------------------------------------------------------

void ps2_print(const void *buf, int len) {
    ee_write(1, buf, (unsigned int)len);
}

// ---------------------------------------------------------------------------
// GS minimal init — clears screen to a solid color via BGCOLOR register
//
// GS Privileged Registers are memory-mapped at 0x12000000.
// BGCOLOR (0x120000E0): R[7:0] | G[15:8] | B[23:16]
// PMODE   (0x12000000): EN1 (bit 0) enables Read Circuit 1, SLBG (bit 6)
//                       makes Read Circuit 1 output BGCOLOR directly.
// SMODE2  (0x12000020): INT[1:0] = 3 → NTSC interlaced frame mode.
// ---------------------------------------------------------------------------

#define GS_REG(offset) (*(volatile uint64_t *)(uintptr_t)(0x12000000U + (offset)))
#define GS_PMODE    GS_REG(0x000)
#define GS_SMODE2   GS_REG(0x020)
#define GS_BGCOLOR  GS_REG(0x0E0)

void ps2_gs_init(void) {
    GS_PMODE  = 0x0000000000000041ULL;  // EN1=1, SLBG=1 (show BGCOLOR), ALP=0
    GS_SMODE2 = 0x0000000000000003ULL;  // NTSC interlaced frame
    // Dark blue: R=0x00, G=0x00, B=0x80
    GS_BGCOLOR = 0x0000000000800000ULL;
}

void ps2_gs_flip(void) {
    // Static BGCOLOR — no flip needed until framebuffer rendering is added.
}
