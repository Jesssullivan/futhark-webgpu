# Futhark WebGPU Mandelbrot Benchmark
# Usage: just <recipe>
# List recipes: just --list

set shell := ["bash", "-euo", "pipefail", "-c"]

# Default: show available commands
default:
    @just --list

# === Build ===

# Compile Mandelbrot to WebGPU (requires futhark with WebGPU backend in PATH)
build:
    cd examples/sebastian-example && futhark webgpu --library -o sebastian sebastian.fut

# Type-check the Futhark source
check:
    cd examples/sebastian-example && futhark check sebastian.fut

# Remove generated artifacts
clean:
    cd examples/sebastian-example && rm -f sebastian.js sebastian.wasm sebastian.json sebastian.c sebastian.wrapper.js

# === Serve ===

# Serve with python3 http.server and COOP/COEP headers
serve: build
    @echo "Serving at http://localhost:8000/"
    @echo "Open in Chrome 133+ / Firefox 141+ / Safari 26+"
    cd examples/sebastian-example && python3 -c "import http.server; \
      h = type('H', (http.server.SimpleHTTPRequestHandler,), \
        {'end_headers': lambda s: (s.send_header('Cross-Origin-Opener-Policy','same-origin'), \
          s.send_header('Cross-Origin-Embedder-Policy','credentialless'), \
          http.server.SimpleHTTPRequestHandler.end_headers(s))}); \
      http.server.HTTPServer(('',8000),h).serve_forever()"
