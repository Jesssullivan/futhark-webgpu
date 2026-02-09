# Futhark WebGPU Demo: Static HTML
# Single standalone.html page with inline diagnostics
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

# Serve with python + COOP/COEP headers (standalone.html)
serve: build
    @echo "Serving at http://localhost:8000/standalone.html"
    @echo "Open in Chrome 133+ / Firefox 141+ / Safari 26+"
    cd {{demo_root}} && python3 -c "import http.server; \
      h = type('H', (http.server.SimpleHTTPRequestHandler,), \
        {'end_headers': lambda s: (s.send_header('Cross-Origin-Opener-Policy','same-origin'), \
          s.send_header('Cross-Origin-Embedder-Policy','credentialless'), \
          http.server.SimpleHTTPRequestHandler.end_headers(s))}); \
      http.server.HTTPServer(('',8000),h).serve_forever()"

# Serve with Caddy (if available)
caddy: build
    @echo "Serving at http://localhost:8080/standalone.html"
    DEMO_ROOT=./{{demo_root}} caddy run --config Caddyfile

# === Container ===

# Build static OCI image via nix2container
container-build:
    nix build .#container-static

# Load OCI image into podman
container-load: container-build
    ./result | podman image load

# Run container (serves at :8080)
container-run:
    podman run --rm -p 8080:8080 futhark-webgpu-static:latest
