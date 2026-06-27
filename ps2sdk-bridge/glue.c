/*
 * ps2sdk-bridge/glue.c — PS2 graphics + w2c2 host glue
 *
 * w2c2 import naming: {module}__{name}(void* instance, ...)
 */

#include <kernel.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#include <gs_psm.h>
#include <dma.h>
#include <graph.h>
#include <draw.h>
#include <draw2d.h>
#include <draw_buffers.h>
#include <draw_tests.h>
#include <packet2.h>

#include "w2c2_base.h"
#include "PS2Demo.h"

/* -------------------------------------------------------------------------
 * Graphics state
 * ------------------------------------------------------------------------- */

#define SCREEN_W   640
#define SCREEN_H   448

/* Each logical pixel renders as a 2x2 block */
#define PIXEL_SCALE 2

/* Max pixels per flush (64*48 = 3072 from the plasma demo) */
#define MAX_PIXELS (64 * 48)

static framebuffer_t g_fb;
static zbuffer_t     g_zb;

typedef struct { int x, y; unsigned char r, g, b; } PendingPixel;
static PendingPixel  g_pixels[MAX_PIXELS];
static int           g_pixel_count = 0;
static unsigned char g_cur_r = 255, g_cur_g = 255, g_cur_b = 255;

/* packet2 buffer — setup(~10 qw) + MAX_PIXELS rects(~3 qw each) + finish(2 qw) */
#define PKT_QWORDS (16 + MAX_PIXELS * 4)
static packet2_t *g_packet = NULL;

static void init_graphics(void) {
    dma_channel_initialize(DMA_CHANNEL_GIF, NULL, 0);
    dma_channel_fast_waits(DMA_CHANNEL_GIF);

    g_fb.width   = SCREEN_W;
    g_fb.height  = 512;          /* VRAM height must be power-of-2 */
    g_fb.mask    = 0;
    g_fb.psm     = GS_PSM_32;
    g_fb.address = graph_vram_allocate(g_fb.width, g_fb.height,
                                       g_fb.psm, GRAPH_ALIGN_PAGE);

    g_zb.enable  = ZTEST_METHOD_ALLPASS;
    g_zb.address = 0;
    g_zb.zsm     = GS_ZBUF_32;
    g_zb.mask    = 1;

    graph_initialize(g_fb.address, g_fb.width, g_fb.height, g_fb.psm, 0, 0);
    graph_set_mode(GRAPH_MODE_INTERLACED, GRAPH_MODE_NTSC,
                   GRAPH_MODE_FIELD, GRAPH_ENABLE);
    graph_set_screen(0, 0, SCREEN_W, SCREEN_H);
    graph_set_bgcolor(0, 0, 0);

    g_packet = packet2_create(PKT_QWORDS, P2_TYPE_NORMAL, P2_MODE_NORMAL, 0);

    /* Clear to black */
    qword_t *q = g_packet->base;
    q = draw_setup_environment(q, 0, &g_fb, &g_zb);
    q = draw_clear(q, 0, 0.0f, 0.0f, (float)g_fb.width, (float)g_fb.height,
                   0, 0, 0);
    q = draw_finish(q);
    dma_channel_send_normal(DMA_CHANNEL_GIF, g_packet->base,
                            q - g_packet->base, 0, 0);
    dma_channel_wait(DMA_CHANNEL_GIF, 0);
    draw_wait_finish();
    graph_wait_vsync();
}

static void flush_pixels(void) {
    if (g_pixel_count == 0) return;

    qword_t *q = g_packet->base;
    q = draw_setup_environment(q, 0, &g_fb, &g_zb);

    int i;
    for (i = 0; i < g_pixel_count; i++) {
        rect_t rect;
        rect.v0.x = (float)(g_pixels[i].x * PIXEL_SCALE);
        rect.v0.y = (float)(g_pixels[i].y * PIXEL_SCALE);
        rect.v0.z = 1;
        rect.v1.x = (float)(g_pixels[i].x * PIXEL_SCALE + PIXEL_SCALE);
        rect.v1.y = (float)(g_pixels[i].y * PIXEL_SCALE + PIXEL_SCALE);
        rect.v1.z = 1;
        rect.color.r = g_pixels[i].r;
        rect.color.g = g_pixels[i].g;
        rect.color.b = g_pixels[i].b;
        rect.color.a = 0x80;
        rect.color.q = 1.0f;
        q = draw_rect_filled(q, 0, &rect);
    }

    q = draw_finish(q);
    dma_channel_send_normal(DMA_CHANNEL_GIF, g_packet->base,
                            q - g_packet->base, 0, 0);
    dma_channel_wait(DMA_CHANNEL_GIF, 0);
    draw_wait_finish();
    g_pixel_count = 0;
}

/* -------------------------------------------------------------------------
 * PS2 host imports
 * ------------------------------------------------------------------------- */

void ps2__print(void* inst, U32 wasm_ptr, U32 len) {
    wasmMemory *mem = PS2Demo_memory((PS2DemoInstance*)inst);
    if (len == 0) return;
    const char *str = (const char*)(mem->data + wasm_ptr);
    U32 j;
    for (j = 0; j < len; j++) putchar((unsigned char)str[j]);
    fflush(stdout);
}

void ps2__clear_screen(void* inst) {
    (void)inst;
    flush_pixels();
    qword_t *q = g_packet->base;
    q = draw_setup_environment(q, 0, &g_fb, &g_zb);
    q = draw_clear(q, 0, 0.0f, 0.0f,
                   (float)g_fb.width, (float)g_fb.height, 0, 0, 0);
    q = draw_finish(q);
    dma_channel_send_normal(DMA_CHANNEL_GIF, g_packet->base,
                            q - g_packet->base, 0, 0);
    dma_channel_wait(DMA_CHANNEL_GIF, 0);
    draw_wait_finish();
}

void ps2__set_color(void* inst, U32 r, U32 g, U32 b) {
    (void)inst;
    g_cur_r = (unsigned char)(r & 0xFF);
    g_cur_g = (unsigned char)(g & 0xFF);
    g_cur_b = (unsigned char)(b & 0xFF);
}

void ps2__draw_pixel(void* inst, U32 x, U32 y) {
    (void)inst;
    if (g_pixel_count >= MAX_PIXELS) flush_pixels();
    g_pixels[g_pixel_count].x = (int)x;
    g_pixels[g_pixel_count].y = (int)y;
    g_pixels[g_pixel_count].r = g_cur_r;
    g_pixels[g_pixel_count].g = g_cur_g;
    g_pixels[g_pixel_count].b = g_cur_b;
    g_pixel_count++;
}

void ps2__vsync(void* inst) {
    (void)inst;
    flush_pixels();
    graph_wait_vsync();
}

void ps2__exit(void* inst, U32 code) {
    (void)inst;
    flush_pixels();
    printf("swift_main exited with code %u\n", (unsigned)code);
    SleepThread();
}

/* -------------------------------------------------------------------------
 * WASI stubs
 * ------------------------------------------------------------------------- */

U32 wasi_snapshot_preview1__args_sizes_get(void* inst, U32 argc_ptr, U32 argv_buf_size_ptr) {
    wasmMemory *mem = PS2Demo_memory((PS2DemoInstance*)inst);
    i32_store(mem, argc_ptr, 0);
    i32_store(mem, argv_buf_size_ptr, 0);
    return 0;
}

U32 wasi_snapshot_preview1__args_get(void* inst, U32 argv_ptr, U32 argv_buf_ptr) {
    (void)inst; (void)argv_ptr; (void)argv_buf_ptr;
    return 0;
}

void wasi_snapshot_preview1__proc_exit(void* inst, U32 code) {
    ps2__exit(inst, code);
}

/* -------------------------------------------------------------------------
 * trap
 * ------------------------------------------------------------------------- */
void trap(Trap t) {
    printf("WASM TRAP %d\n", (int)t);
    SleepThread();
    while (1) {}
}

/* -------------------------------------------------------------------------
 * EE main
 * ------------------------------------------------------------------------- */
int main(int argc, char** argv) {
    (void)argc; (void)argv;

    printf("swift-embedded-ps2 booting...\n");
    init_graphics();
    printf("GS initialized. Running swift_main...\n");

    static PS2DemoInstance instance;
    PS2DemoInstantiate(&instance, NULL);
    PS2Demo_swift_main(&instance);

    SleepThread();
    return 0;
}
