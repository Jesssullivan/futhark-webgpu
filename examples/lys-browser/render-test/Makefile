# Lys browser PoC for futhark-webgpu
# Builds a WebGPU browser bundle from genlys.fut.

PROG   := lys
WRAP   := genlys.fut
FUT    := lys.fut
BUILD  := build
OUT    := $(BUILD)/$(PROG)
LYS_PKG := github.com/diku-dk/lys

GEN := $(OUT).js \
       $(OUT).wasm \
       $(OUT).json \
       $(OUT).c \
       $(OUT).wrapper.js

.PHONY: all setup gen check clean serve

all: gen

setup:
	@if [ ! -f futhark.pkg ]; then printf 'require {\n}\n' > futhark.pkg; fi
	@if ! grep -q '$(LYS_PKG)' futhark.pkg; then futhark pkg add $(LYS_PKG); fi
	futhark pkg sync

$(BUILD):
	mkdir -p $(BUILD)

gen: setup $(GEN)

$(GEN): $(WRAP) $(FUT) | $(BUILD)
	futhark webgpu --library -o $(OUT) $(WRAP)

check: setup
	futhark check $(WRAP)

clean:
	rm -rf $(BUILD)

serve: gen
	python3 -m http.server 8000