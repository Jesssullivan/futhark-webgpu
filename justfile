# Futhark WebGPU Demo: Flask
# Serves Mandelbrot with COOP/COEP headers via Flask
#
# Usage: just <recipe>
# List recipes: just --list

set shell := ["bash", "-euo", "pipefail", "-c"]

demo_root := "examples/sebastian-example"

# Default: show available commands
default:
    @just --list

# === Build ===

# Compile Mandelbrot to WebGPU (requires futhark with WebGPU backend in PATH)
build:
    cd {{demo_root}} && futhark webgpu --library -o sebastian sebastian.fut

# Type-check the Futhark source
check:
    cd {{demo_root}} && futhark check sebastian.fut

# Remove generated artifacts
clean:
    cd {{demo_root}} && rm -f sebastian.js sebastian.wasm sebastian.json sebastian.c sebastian.wrapper.js

# === Serve ===

# Serve with Flask (COOP/COEP headers for SharedArrayBuffer + WebGPU)
serve: build
    @echo "Open in Chrome 133+ / Firefox 141+ / Safari 26+"
    DEMO_ROOT=./{{demo_root}} python3 app.py --port 8000

# === Container ===

# Build OCI image via nix2container
container-build:
    nix build .#container-flask

# Load OCI image into podman
container-load: container-build
    ./result | podman image load

# Run container (serves at :8000)
container-run:
    podman run --rm -p 8000:8000 futhark-webgpu-flask:latest

# Build via Containerfile (fallback without Nix)
container-build-podman: build
    podman build -t futhark-webgpu-flask -f Containerfile.flask .
