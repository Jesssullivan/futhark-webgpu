# Futhark WebGPU Demo: Caddy
# Serves Mandelbrot with COOP/COEP headers via Caddy reverse proxy
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

# Serve with Caddy (COOP/COEP headers for SharedArrayBuffer + WebGPU)
serve: build
    @echo "Serving at http://localhost:8080/"
    @echo "COOP/COEP headers enabled for SharedArrayBuffer and WebGPU."
    @echo "Open in Chrome 133+ / Firefox 141+ / Safari 26+"
    DEMO_ROOT=./{{demo_root}} caddy run --config Caddyfile

# === Container ===

# Build OCI image via nix2container
container-build:
    nix build .#container-caddy

# Load OCI image into podman
container-load: container-build
    ./result | podman image load

# Run container (serves at :8080)
container-run:
    podman run --rm -p 8080:8080 futhark-webgpu-caddy:latest

# Build via Containerfile (fallback without Nix)
container-build-podman: build
    podman build -t futhark-webgpu-caddy -f Containerfile .
