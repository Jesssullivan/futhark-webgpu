(async function () {
  const canvas = document.getElementById("surface");
  const statusEl = document.getElementById("status");
  const restartBtn = document.getElementById("restartBtn");
  const renderBtn = document.getElementById("renderBtn");
  const ctx = canvas.getContext("2d", { alpha: true });

  let emModule = null;
  let fut = null;

  function setStatus(...lines) {
    statusEl.textContent = lines.join("\n");
  }

  function isLittleEndian() {
    const b = new ArrayBuffer(4);
    new Uint32Array(b)[0] = 0x01020304;
    return new Uint8Array(b)[0] === 0x04;
  }

  const littleEndian = isLittleEndian();

  function argbToAbgr(x) {
    x = x >>> 0;
    return (
      (x & 0xFF00FF00) |
      ((x & 0x00FF0000) >>> 16) |
      ((x & 0x000000FF) << 16)
    ) >>> 0;
  }

  function argbToRgbaBE(x) {
    x = x >>> 0;
    return ((x << 8) | (x >>> 24)) >>> 0;
  }

  function argbToCanvasWord(x) {
    return littleEndian ? argbToAbgr(x) : argbToRgbaBE(x);
  }

  function drawU32(pixelsU32, w, h) {
    const img = ctx.createImageData(w, h);
    const dst = new Uint32Array(img.data.buffer);
    dst.set(pixelsU32);
    ctx.putImageData(img, 0, 0);
  }

  function loadScriptOnce(url) {
    return new Promise((resolve, reject) => {
      const existing = document.querySelector(`script[src="${url}"]`);
      if (existing) {
        resolve();
        return;
      }

      const s = document.createElement("script");
      s.src = url;
      s.onload = resolve;
      s.onerror = () => reject(new Error(`Failed to load ${url}`));
      document.head.appendChild(s);
    });
  }

  function getCanvasSize() {
    const rect = canvas.getBoundingClientRect();
    return {
      width: Math.max(1, Math.floor(rect.width)),
      height: Math.max(1, Math.floor(rect.height)),
    };
  }

  async function ensureFutharkReady() {
    if (fut) return;

    setStatus("Loading build/lys.js...");
    await loadScriptOnce("build/lys.js");

    if (typeof Module !== "function" || typeof FutharkModule !== "function") {
      throw new Error("build/lys.js loaded, but Module/FutharkModule were not found.");
    }

    setStatus("Initializing Emscripten module...");
    emModule = await Module();

    setStatus("Creating Futhark WebGPU context...");
    fut = new FutharkModule();
    await fut.init(emModule);

    setStatus("Futhark runtime ready.");
  }

  async function renderOnce() {
    await ensureFutharkReady();

    const { width, height } = getCanvasSize();
    canvas.width = width;
    canvas.height = height;

    setStatus(
      "Futhark runtime ready.",
      `Canvas size: ${width} x ${height}`,
      "Testing render_once..."
    );

    console.log("entry keys:", Object.keys(fut.entry));

    const seed = Date.now() >>> 0;
    const [buf] = await fut.entry.render_once(seed, height, width);
    console.log("render_once raw return:", buf);

    const argb = await buf.values();
    buf.free();

    console.log("render_once pixel count:", argb.length);

    if (argb.length !== width * height) {
      throw new Error(`Expected ${width * height} pixels, got ${argb.length}.`);
    }

    const fixed = new Uint32Array(argb.length);
    for (let i = 0; i < argb.length; i++) {
      fixed[i] = argbToCanvasWord(argb[i]);
    }

    drawU32(fixed, width, height);

    setStatus(
      "Futhark runtime ready.",
      `Canvas size: ${width} x ${height}`,
      "Rendered one frame successfully with render_once."
    );
  }

  async function restart() {
    await renderOnce();
  }

  restartBtn.addEventListener("click", async () => {
    try {
      await restart();
    } catch (err) {
      console.error(err);
      setStatus("ERROR in restart button", err?.message || String(err));
    }
  });

  renderBtn.addEventListener("click", async () => {
    try {
      await renderOnce();
    } catch (err) {
      console.error(err);
      setStatus("ERROR in render button", err?.message || String(err));
    }
  });

  window.addEventListener("resize", async () => {
    if (!fut) return;
    try {
      await renderOnce();
    } catch (err) {
      console.error(err);
      setStatus("ERROR on window resize", err?.message || String(err));
    }
  });

  try {
    await restart();
  } catch (err) {
    console.error(err);
    setStatus("ERROR on startup", err?.message || String(err));
  }
})();