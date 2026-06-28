# =============================================================================
# swift-embedded-ps2 — Makefile
#
# Pipeline:
#   1. swift build  → build/PS2Demo.wasm      (Embedded Swift, wasm32)
#   2. w2c2         → build/PS2Demo.c/.h      (portable C89)
#   3. ps2-gcc      → build/PS2Demo.elf        (MIPS R5900 EE executable)
#
# Prerequisites (all available via Docker — see README):
#   - Swift toolchain with wasm32-unknown-none-wasm Embedded SDK
#   - w2c2  (https://github.com/turbolent/w2c2)
#   - ps2dev Docker image (ps2dev/ps2dev:latest)
#
# Quick start:
#   make wasm          # Step 1 only (run on host with Swift toolchain)
#   make c             # Step 2 only (run on host with w2c2)
#   make elf           # Step 3 only (run inside ps2dev Docker)
#   make all           # All steps (requires all tools on PATH)
#   make docker-elf    # Steps 2+3 inside ps2dev Docker automatically
# =============================================================================

# -----------------------------------------------------------------------------
# Configuration
# -----------------------------------------------------------------------------

MODULE      := PS2Demo
WASM_TARGET := wasm32-unknown-none-wasm

# Swift SDK identifier — install with:
#   swift sdk install https://download.swift.org/swift-6.2-release/wasm-sdk/...
SWIFT_SDK   := swift-DEVELOPMENT-SNAPSHOT-2026-06-24-a_wasm-embedded

# w2c2 binary (build from source or `brew install w2c2` if available)
W2C2        := /tmp/w2c2-build/w2c2/w2c2

# ps2dev toolchain (inside Docker these are on PATH)
PS2_CC      := mips64r5900el-ps2-elf-gcc
PS2DEV      ?= /usr/local/ps2dev
PS2SDK      ?= $(PS2DEV)/ps2sdk

# Build artefact locations
BUILD       := build
WASM_OUT    := $(BUILD)/$(MODULE).wasm
C_OUT       := $(BUILD)/$(MODULE).c
H_OUT       := $(BUILD)/$(MODULE).h
ELF_OUT     := $(BUILD)/$(MODULE).elf

# w2c2 include path (the w2c2_base.h we ship is illustrative;
# replace with real one from w2c2 repo)
W2C2_INC    := w2c2-include

# Number of functions per w2c2 output file (tune for large modules)
W2C2_CHUNK  := 100

# ps2-gcc flags
PS2_CFLAGS  := \
    -D_EE \
    -G0 \
    -O2 \
    -I$(W2C2_INC) \
    -I$(PS2SDK)/ee/include \
    -I$(PS2SDK)/common/include \
    -I$(BUILD)

PS2_LDFLAGS := \
    -T$(PS2SDK)/ee/startup/linkfile \
    -L$(PS2SDK)/ee/lib \
    -lkernel -ldraw -lgraph -ldma -lpacket2 -lc -lm

# -----------------------------------------------------------------------------
# Targets
# -----------------------------------------------------------------------------

.PHONY: all wasm c elf clean docker-elf help

all: wasm c elf

## Step 1 — Embedded Swift → WASM
wasm: $(WASM_OUT)

$(BUILD):
	mkdir -p $(BUILD)

$(WASM_OUT): Sources/$(MODULE)/main.swift Package.swift | $(BUILD)
	@echo "==> [1/3] Building Embedded Swift → WASM"
	swift build \
	    --swift-sdk $(SWIFT_SDK) \
	    --configuration release \
	    --scratch-path $(BUILD)/.build
	@# Locate the .wasm output — path varies by toolchain version
	@find $(BUILD)/.build -name "$(MODULE).wasm" | head -1 | \
	    xargs -I{} cp {} $(WASM_OUT)
	@echo "    Output: $(WASM_OUT)"
	@ls -lh $(WASM_OUT)

## Step 2 — WASM → C89 via w2c2
c: $(C_OUT)

$(C_OUT): $(WASM_OUT)
	@echo "==> [2/3] Transpiling WASM → C89 via w2c2"
	$(W2C2) \
	    -f $(W2C2_CHUNK) \
	    $(WASM_OUT) \
	    $(BUILD)/$(MODULE).c
	@echo "    Output: $(C_OUT), $(H_OUT)"
	@wc -l $(C_OUT) || true

## Step 3 — C89 → MIPS R5900 ELF via ps2dev GCC
elf: $(ELF_OUT)

$(ELF_OUT): $(C_OUT) ps2sdk-bridge/glue.c
	@echo "==> [3/3] Compiling C89 → MIPS R5900 ELF via $(PS2_CC)"
	$(PS2_CC) \
	    $(PS2_CFLAGS) \
	    $(C_OUT) \
	    ps2sdk-bridge/glue.c \
	    $(PS2_LDFLAGS) \
	    -o $(ELF_OUT)
	@echo "    Output: $(ELF_OUT)"
	@ls -lh $(ELF_OUT)
	@echo ""
	@echo "    Load in PCSX2: File → Run ELF → $(ELF_OUT)"

## Run steps 2+3 inside ps2dev Docker (step 1 must already have produced .wasm)
docker-elf:
	@echo "==> Running w2c2 + ps2-gcc inside ps2dev/ps2dev Docker"
	docker run --rm \
	    -v "$(CURDIR):/project" \
	    -w /project \
	    ps2dev/ps2dev \
	    sh -c "apk add --no-cache cmake git build-base && \
	           git clone --depth 1 https://github.com/turbolent/w2c2 /tmp/w2c2 && \
	           cmake -S /tmp/w2c2 -B /tmp/w2c2-build -DCMAKE_BUILD_TYPE=Release && \
	           cmake --build /tmp/w2c2-build -j\$$(nproc) && \
	           /tmp/w2c2-build/w2c2/w2c2 -p /project/$(WASM_OUT) /project/$(C_OUT) && \
	           $(PS2_CC) $(PS2_CFLAGS) /project/$(C_OUT) /project/ps2sdk-bridge/glue.c \
	               $(PS2_LDFLAGS) -o /project/$(ELF_OUT)"

## Convenience: print ELF info (requires ps2dev toolchain or Docker)
info: $(ELF_OUT)
	mips64r5900el-ps2-elf-readelf -h $(ELF_OUT)

clean:
	rm -rf $(BUILD)

help:
	@echo ""
	@echo "swift-embedded-ps2 build targets:"
	@echo "  make wasm        Step 1: Swift → WASM  (needs Swift + Embedded WASM SDK)"
	@echo "  make c           Step 2: WASM → C89    (needs w2c2)"
	@echo "  make elf         Step 3: C89 → ELF     (needs ps2dev toolchain)"
	@echo "  make all         All three steps"
	@echo "  make docker-elf  Steps 2+3 inside ps2dev/ps2dev Docker"
	@echo "  make clean       Remove build/ directory"
	@echo ""
	@echo "Docker quick-start (after 'make wasm' on host):"
	@echo "  make docker-elf"
	@echo ""
	@echo "Test in emulator:"
	@echo "  PCSX2 → File → Run ELF → build/$(MODULE).elf"
	@echo ""
