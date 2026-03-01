# Example: Interface compare (Futhark WebGPU vs WASM)

PROG  := probe
FUT   := $(PROG).fut
DIR   := build

WEBGPU_OUT := $(DIR)/$(PROG)_webgpu
WASM_OUT   := $(DIR)/$(PROG)_wasm

WEBGPU_GEN := $(WEBGPU_OUT).js \
              $(WEBGPU_OUT).wasm \
              $(WEBGPU_OUT).json \
              $(WEBGPU_OUT).c \
              $(WEBGPU_OUT).wrapper.js

# NOTE: some Futhark versions output .js instead of .mjs for wasm.
# If your build produces .js, change the line below accordingly.
WASM_GEN   := $(WASM_OUT).mjs \
              $(WASM_OUT).wasm

.PHONY: all gen clean serve check

all: gen

# "gen" builds generated artifacts (phony name that does NOT clash with DIR)
gen: $(WEBGPU_GEN) $(WASM_GEN)

# Create the output directory (real directory target)
$(DIR):
	mkdir -p $(DIR)

# WebGPU: one invocation generates all outputs
$(WEBGPU_GEN): $(FUT) | $(DIR)
	futhark webgpu --library -o $(WEBGPU_OUT) $(FUT)

# WASM: one invocation generates outputs
$(WASM_GEN): $(FUT) | $(DIR)
	futhark wasm --library -o $(WASM_OUT) $(FUT)

check:
	futhark check $(FUT)

clean:
	rm -rf $(DIR)

serve: gen
	python3 -m http.server 8000