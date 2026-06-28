/*
 * ps2sdk-bridge/glue.c — PS2 graphics + w2c2 host glue (gsKit FFI)
 *
 * Swift handles all rendering logic via FFI imports.
 * This file provides: gsKit init, GSGLOBAL accessors, and thin
 * wrappers around math3d/draw/gsKit functions that operate on
 * raw pointers (since w2c2 passes WASM memory offsets as U32).
 *
 * w2c2 import naming: {module}__{name}(void* instance, ...)
 */

#include <kernel.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <malloc.h>

#include <tamtypes.h>
#include <gsKit.h>
#include <gsInline.h>
#include <dmaKit.h>
#include <draw.h>
#include <draw3d.h>
#include <math3d.h>

#include "w2c2_base.h"
#include "PS2Demo.h"

/* -------------------------------------------------------------------------
 * Graphics state
 * ------------------------------------------------------------------------- */

static GSGLOBAL *g_gsGlobal = NULL;

/* -------------------------------------------------------------------------
 * gsKit initialization
 * ------------------------------------------------------------------------- */

void ps2__gs_init(void* inst) {
    (void)inst;

    g_gsGlobal = gsKit_init_global();
    g_gsGlobal->PrimAlphaEnable = GS_SETTING_ON;
    gsKit_set_primalpha(g_gsGlobal, GS_SETREG_ALPHA(0, 1, 0, 1, 0), 0);

    dmaKit_init(D_CTRL_RELE_OFF, D_CTRL_MFD_OFF, D_CTRL_STS_UNSPEC,
                D_CTRL_STD_OFF, D_CTRL_RCYC_8, 1 << DMA_CHANNEL_GIF);
    dmaKit_chan_init(DMA_CHANNEL_GIF);

    gsKit_set_clamp(g_gsGlobal, GS_CMODE_REPEAT);
    gsKit_vram_clear(g_gsGlobal);
    gsKit_init_screen(g_gsGlobal);
    gsKit_mode_switch(g_gsGlobal, GS_ONESHOT);
}

/* -------------------------------------------------------------------------
 * gsKit flip
 * ------------------------------------------------------------------------- */

void ps2__gsKit_flip_screen(void* inst) {
    (void)inst;
    gsKit_queue_exec(g_gsGlobal);
    gsKit_sync_flip(g_gsGlobal);
}

/* -------------------------------------------------------------------------
 * GSGLOBAL accessors (return U32 since w2c2 uses 32-bit pointers)
 * ------------------------------------------------------------------------- */

U32 ps2__gsKit_global_get(void* inst) {
    (void)inst;
    return (U32)(size_t)g_gsGlobal;
}

U32 ps2__gsKit_global_get_width(void* inst, U32 gs) {
    (void)inst;
    return ((GSGLOBAL*)(size_t)gs)->Width;
}

U32 ps2__gsKit_global_get_height(void* inst, U32 gs) {
    (void)inst;
    return ((GSGLOBAL*)(size_t)gs)->Height;
}

U32 ps2__gsKit_global_get_psmz(void* inst, U32 gs) {
    (void)inst;
    return ((GSGLOBAL*)(size_t)gs)->PSMZ;
}

U32 ps2__gsKit_global_get_zbuffering(void* inst, U32 gs) {
    (void)inst;
    return ((GSGLOBAL*)(size_t)gs)->ZBuffering;
}

void ps2__gsKit_global_set_primaaenable(void* inst, U32 gs, U32 value) {
    (void)inst;
    ((GSGLOBAL*)(size_t)gs)->PrimAAEnable = value;
}

void ps2__gsKit_global_set_zbuffering(void* inst, U32 gs, U32 value) {
    (void)inst;
    ((GSGLOBAL*)(size_t)gs)->ZBuffering = value;
}

void ps2__gsKit_set_test(void* inst, U32 gs, U32 test) {
    (void)inst;
    gsKit_set_test((GSGLOBAL*)(size_t)gs, test);
}

void ps2__gsKit_clear(void* inst, U32 gs, U64 color) {
    (void)inst;
    gsKit_clear((GSGLOBAL*)(size_t)gs, color);
}

void ps2__gsKit_prim_list_triangle_gouraud_3d(void* inst, U32 gs, U32 count, U32 vertices_ptr) {
    (void)inst;
    wasmMemory *mem = PS2Demo_memory((PS2DemoInstance*)inst);
    GSPRIMPOINT *vertices = (GSPRIMPOINT*)(mem->data + vertices_ptr);
    gsKit_prim_list_triangle_gouraud_3d((GSGLOBAL*)(size_t)gs, count, vertices);
}

/* -------------------------------------------------------------------------
 * math3d wrappers (operate on WASM memory offsets)
 * ------------------------------------------------------------------------- */

void ps2__create_view_screen(void* inst, U32 matrix_ptr,
    F32 aspect, F32 left, F32 right, F32 top, F32 bottom, F32 near, F32 ffar) {
    (void)inst;
    wasmMemory *mem = PS2Demo_memory((PS2DemoInstance*)inst);
    MATRIX *m = (MATRIX*)(mem->data + matrix_ptr);
    create_view_screen(*m, aspect, left, right, top, bottom, near, ffar);
}

void ps2__create_local_world(void* inst, U32 matrix_ptr, U32 position_ptr, U32 rotation_ptr) {
    (void)inst;
    wasmMemory *mem = PS2Demo_memory((PS2DemoInstance*)inst);
    MATRIX *m = (MATRIX*)(mem->data + matrix_ptr);
    VECTOR *pos = (VECTOR*)(mem->data + position_ptr);
    VECTOR *rot = (VECTOR*)(mem->data + rotation_ptr);
    create_local_world(*m, *pos, *rot);
}

void ps2__create_world_view(void* inst, U32 matrix_ptr, U32 position_ptr, U32 rotation_ptr) {
    (void)inst;
    wasmMemory *mem = PS2Demo_memory((PS2DemoInstance*)inst);
    MATRIX *m = (MATRIX*)(mem->data + matrix_ptr);
    VECTOR *pos = (VECTOR*)(mem->data + position_ptr);
    VECTOR *rot = (VECTOR*)(mem->data + rotation_ptr);
    create_world_view(*m, *pos, *rot);
}

void ps2__create_local_screen(void* inst, U32 result_ptr, U32 local_world_ptr, U32 world_view_ptr, U32 view_screen_ptr) {
    (void)inst;
    wasmMemory *mem = PS2Demo_memory((PS2DemoInstance*)inst);
    MATRIX *result = (MATRIX*)(mem->data + result_ptr);
    MATRIX *local_world = (MATRIX*)(mem->data + local_world_ptr);
    MATRIX *world_view = (MATRIX*)(mem->data + world_view_ptr);
    MATRIX *view_screen = (MATRIX*)(mem->data + view_screen_ptr);
    create_local_screen(*result, *local_world, *world_view, *view_screen);
}

void ps2__calculate_vertices(void* inst, U32 output_ptr, U32 count, U32 input_ptr, U32 matrix_ptr) {
    (void)inst;
    wasmMemory *mem = PS2Demo_memory((PS2DemoInstance*)inst);
    VECTOR *output = (VECTOR*)(mem->data + output_ptr);
    VECTOR *input = (VECTOR*)(mem->data + input_ptr);
    MATRIX *matrix = (MATRIX*)(mem->data + matrix_ptr);
    calculate_vertices(output, count, input, *matrix);
}

/* -------------------------------------------------------------------------
 * draw wrappers
 * ------------------------------------------------------------------------- */

void ps2__draw_convert_rgbq(void* inst, U32 colors_ptr, U32 count, U32 vertices_ptr, U32 colour_f_ptr, U32 q) {
    (void)inst;
    wasmMemory *mem = PS2Demo_memory((PS2DemoInstance*)inst);
    color_t *colors = (color_t*)(mem->data + colors_ptr);
    vertex_f_t *vertices = (vertex_f_t*)(mem->data + vertices_ptr);
    color_f_t *colour_f = (color_f_t*)(mem->data + colour_f_ptr);
    draw_convert_rgbq(colors, count, vertices, colour_f, q);
}

U64 ps2__color_to_rgbaq(void* inst, U32 r, U32 g, U32 b, U32 a, F32 q) {
    (void)inst;
    return (U64)color_to_RGBAQ(r, g, b, a, q);
}

U64 ps2__vertex_to_xyz2(void* inst, U32 gs, F32 x, F32 y, F32 z) {
    (void)inst;
    return (U64)vertex_to_XYZ2((GSGLOBAL*)(size_t)gs, x, y, z);
}

/* Build GSPRIMPOINT array from screen-space vertices and colors, then draw.
 * Lives here because gs_rgbaq / gs_xyz2 are 128-bit types that can't be
 * constructed from WASM-side Swift without losing the GS packet tag bits. */
void ps2__build_and_draw(void* inst, U32 gs, U32 n,
                          U32 screen_verts_ptr, U32 colors_ptr) {
    wasmMemory *mem = PS2Demo_memory((PS2DemoInstance*)inst);
    vertex_f_t *sv  = (vertex_f_t*)(mem->data + screen_verts_ptr);
    color_t    *col = (color_t*)   (mem->data + colors_ptr);
    GSGLOBAL   *gsGlobal = (GSGLOBAL*)(size_t)gs;

    GSPRIMPOINT *gv = memalign(128, sizeof(GSPRIMPOINT) * n);
    for (U32 i = 0; i < n; i++) {
        gv[i].rgbaq = color_to_RGBAQ(col[i].r, col[i].g, col[i].b, col[i].a, 0.0f);
        gv[i].xyz2  = vertex_to_XYZ2(gsGlobal, sv[i].x, sv[i].y, (int)sv[i].z);
    }
    gsKit_prim_list_triangle_gouraud_3d(gsGlobal, n, gv);
    free(gv);
}

/* -------------------------------------------------------------------------
 * Memory management
 * ------------------------------------------------------------------------- */

U32 ps2__memalign(void* inst, U32 alignment, U32 size) {
    (void)inst;
    void *ptr = memalign(alignment, size);
    return (U32)(size_t)ptr;
}

void ps2__free(void* inst, U32 ptr) {
    (void)inst;
    free((void*)(size_t)ptr);
}

/* -------------------------------------------------------------------------
 * Print / Exit
 * ------------------------------------------------------------------------- */

void ps2__print(void* inst, U32 wasm_ptr, U32 len) {
    wasmMemory *mem = PS2Demo_memory((PS2DemoInstance*)inst);
    if (len == 0) return;
    const char *str = (const char*)(mem->data + wasm_ptr);
    U32 j;
    for (j = 0; j < len; j++) putchar((unsigned char)str[j]);
    fflush(stdout);
}

void ps2__exit(void* inst, U32 code) {
    (void)inst;
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
    printf("Initializing gsKit...\n");
    ps2__gs_init(NULL);
    printf("GS initialized. Running swift_main...\n");

    static PS2DemoInstance instance;
    PS2DemoInstantiate(&instance, NULL);
    PS2Demo_swift_main(&instance);

    SleepThread();
    return 0;
}
