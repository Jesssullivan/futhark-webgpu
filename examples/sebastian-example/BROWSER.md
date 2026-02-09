# Browser Requirements

## Minimum Versions

| Browser | Version | Notes |
|---------|---------|-------|
| Chrome  | 133+    | Float16Array + WebGPU (default since 113) |
| Firefox | 141+    | WebGPU shipped |
| Safari  | 26+     | WebGPU shipped |

## Chrome Flags (Linux headless / CI testing)

For headless testing without a GPU, these Chrome flags enable
SwiftShader software rendering:

```
--enable-unsafe-webgpu
--use-webgpu-adapter=swiftshader
--enable-features=Vulkan
--disable-gpu-blocklist
--disable-vulkan-surface
--headless=new
```

## Useful Chrome Pages

- `chrome://gpu` - Verify hardware acceleration and WebGPU status
- `chrome://flags/#enable-unsafe-webgpu` - Force-enable WebGPU
- `chrome://flags/#force-high-performance-gpu` - Prefer discrete GPU

## Required HTTP Headers

WebGPU demos require these headers for `SharedArrayBuffer` support:

```
Cross-Origin-Opener-Policy: same-origin
Cross-Origin-Embedder-Policy: credentialless
```

A plain `python3 -m http.server` will NOT work.
Use Flask (`app.py`), the provided Containerfile, or the `just serve` recipe.

## Known Issues

- **Float16Array**: Not available in Chrome < 133. The generated
  `wrapper.js` references `Float16Array` unconditionally (line 32).
  A polyfill extending `Uint16Array` can work for older browsers
  but is not officially supported.

- **ShaderF16**: Some GPUs do not support `WGPUFeatureName_ShaderF16`.
  This causes "Could not get WebGPU device" errors. A fix to make
  this feature request conditional is tracked upstream.
