const out = document.getElementById("out");
const btn = document.getElementById("run");

function p(line = "") { out.textContent += line + "\n"; }
function hr() { p("------------------------------------------------------------"); }

function keys(obj) { return Object.keys(obj ?? {}).sort(); }

async function checkWasm() {
  p("WASM:");
  const wasmMod = await import("./build/probe_wasm.mjs");
  p("  module exports: " + keys(wasmMod).join(", "));
  p("  has newFutharkContext(): " + (typeof wasmMod.newFutharkContext === "function"));
  p("  has default loader export: " + (typeof wasmMod.default === "function"));

  // create the context object
  let ctx = null;
  try {
    ctx = await wasmMod.newFutharkContext();
    p("  newFutharkContext(): ok");
  } catch (e) {
    p("  newFutharkContext(): failed -> " + String(e?.message ?? e));
    return;
  }

  // Entry points are typically instance properties (not prototype methods)
  const ctxKeys = keys(ctx);
  p("  context keys: " + ctxKeys.join(", "));

  // if entry point table exists, print it
  if (typeof ctx.get_entry_points === "function") {
    const eps = ctx.get_entry_points();
    p("  entry points:");
    for (const name of Object.keys(eps).sort()) {
      const ins = eps[name][1].join(", ");
      const outs = eps[name][2].join(", ");
      p(`    ${name}: (${ins}) -> (${outs})`);
    }
  } else if (ctx.entry_points) {
    p("  entry points: present (ctx.entry_points)");
  } else {
    p("  entry points: not found (no get_entry_points/entry_points)");
  }


  if (typeof ctx.free === "function") ctx.free();
}

async function checkWebGPU() {
  p("WebGPU:");
  p("  has global Module(): " + (typeof Module === "function"));
  p("  has global FutharkModule: " + (typeof FutharkModule === "function"));

  if (typeof Module !== "function" || typeof FutharkModule !== "function") {
    p("  cannot inspect further (missing globals)");
    return;
  }

  // create the wrapper object
  const m = await Module();
  const fut = new FutharkModule();
  await fut.init(m);

  p("  fut keys: " + keys(fut).join(", "));
  p("  fut.entry keys: " + keys(fut.entry).join(", "));

  // input kinds from the manifest
  const eps = fut.manifest?.entry_points ?? {};
  for (const name of keys(eps)) {
    const ins = eps[name].inputs.map((x) => x.type).join(", ");
    const outs = eps[name].outputs.map((x) => x.type).join(", ");
    p(`  entry ${name}: (${ins}) -> (${outs})`);
  }

  // Detect whether array inputs require FutharkArray (your generated wrapper throws that)
  // We can infer this by looking at fut.manifest.types entries of kind "array".
  const arrayTypes = [];
  for (const [tname, tinfo] of Object.entries(fut.manifest?.types ?? {})) {
    if (tinfo?.kind === "array") arrayTypes.push(tname);
  }
  p("  manifest array types: " + arrayTypes.sort().join(", "));

}


btn.addEventListener("click", async () => {
  out.textContent = "";
  p("Checking generated JS interfaces...");
  hr();

  try { await checkWasm(); }
  catch (e) { p("WASM check failed: " + String(e?.stack ?? e)); }

  hr();

  try { await checkWebGPU(); }
  catch (e) { p("WebGPU check failed: " + String(e?.stack ?? e)); }

  hr();
});