# Containerfile for Futhark WebGPU Mandelbrot Demo
# Fallback for non-Nix users (prefer nix2container via flake.nix)
#
# Usage:
#   # Build (assumes pre-compiled WebGPU artifacts in examples/sebastian-example/)
#   podman build -t futhark-webgpu-demo -f Containerfile .
#
#   # Run
#   podman run --rm -p 8080:8080 futhark-webgpu-demo
#
#   # Open http://localhost:8080/ in a WebGPU-capable browser

FROM docker.io/library/caddy:2-alpine

# Inline Caddyfile with COOP/COEP headers for WebGPU/SharedArrayBuffer
RUN printf '{\n\tadmin off\n\tauto_https off\n}\n\nhttp://:8080 {\n\theader Cross-Origin-Opener-Policy "same-origin"\n\theader Cross-Origin-Embedder-Policy "credentialless"\n\t@wasm path *.wasm\n\theader @wasm Content-Type "application/wasm"\n\thandle /healthz {\n\t\trespond "OK" 200\n\t}\n\troot * /srv\n\tfile_server\n}\n' > /etc/caddy/Caddyfile

# Copy the compiled demo files (build with: futhark webgpu --library -o sebastian sebastian.fut)
COPY examples/sebastian-example/*.html /srv/
COPY examples/sebastian-example/*.js /srv/
COPY examples/sebastian-example/*.wasm /srv/
COPY examples/sebastian-example/*.json /srv/

EXPOSE 8080

CMD ["caddy", "run", "--config", "/etc/caddy/Caddyfile"]
