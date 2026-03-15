(function () {
  const surface = document.getElementById("surface");
  const dot = document.getElementById("dot");
  const latestEl = document.getElementById("latest");
  const logEl = document.getElementById("log");
  const clearBtn = document.getElementById("clearBtn");
  const focusBtn = document.getElementById("focusBtn");

  const MAX_LOG_LINES = 100;
  let logLines = [];

  // SDL keycodes used by the Lys demo
  const SDLK = {
    BACKSPACE: 8,
    TAB: 9,
    RETURN: 13,
    ESCAPE: 27,
    SPACE: 32,

    F1: 0x4000003A,

    RIGHT: 0x4000004F,
    LEFT: 0x40000050,
    DOWN: 0x40000051,
    UP: 0x40000052,
  };

  function appendLog(line) {
    logLines.push(line);
    if (logLines.length > MAX_LOG_LINES) {
      logLines = logLines.slice(logLines.length - MAX_LOG_LINES);
    }
    logEl.textContent = logLines.join("\n");
    logEl.scrollTop = logEl.scrollHeight;
  }

  function showPayload(obj) {
    const line = JSON.stringify(obj);
    latestEl.textContent = JSON.stringify(obj, null, 2);
    appendLog(line);
  }

  function clearLog() {
    logLines = [];
    logEl.textContent = "";
  }

  // Use event.key, not event.code:
  // - SDL keycodes are layout/character based for printable keys.
  // - event.code is physical-key based.
  function jsKeyToSDL(event) {
    switch (event.key) {
      case "ArrowRight": return SDLK.RIGHT;
      case "ArrowLeft": return SDLK.LEFT;
      case "ArrowDown": return SDLK.DOWN;
      case "ArrowUp": return SDLK.UP;

      case "Escape": return SDLK.ESCAPE;
      case "Enter": return SDLK.RETURN;
      case "Tab": return SDLK.TAB;
      case "Backspace": return SDLK.BACKSPACE;
      case "F1": return SDLK.F1;
      case " ": return SDLK.SPACE;

      default:
        if (event.key.length === 1) {
          return event.key.toLowerCase().codePointAt(0) ?? 0;
        }
        return 0;
    }
  }

  // Browser event.buttons:
  // 1 left, 2 right, 4 middle, 8 back, 16 forward
  // SDL/Lys button mask order:
  // left=1, middle=2, right=4, x1=8, x2=16
  function browserButtonsToSDLMask(buttons) {
    let mask = 0;
    if (buttons & 1) mask |= 1;   // left
    if (buttons & 4) mask |= 2;   // middle
    if (buttons & 2) mask |= 4;   // right
    if (buttons & 8) mask |= 8;   // x1
    if (buttons & 16) mask |= 16; // x2
    return mask;
  }

  function wheelDeltaToStep(delta) {
    if (delta < 0) return 1;
    if (delta > 0) return -1;
    return 0;
  }

  function localXY(event) {
    return {
      x: Math.floor(event.offsetX),
      y: Math.floor(event.offsetY),
    };
  }

  function moveDot(x, y) {
    dot.style.left = `${x}px`;
    dot.style.top = `${y}px`;
  }

  // translate browser events to the format expected by the Lys demo, and emit them.
  function translateKeyDown(event) {
    const key = jsKeyToSDL(event);
    if (key === 0) return null;
    return { "#keydown": { key } };
  }

  function translateKeyUp(event) {
    const key = jsKeyToSDL(event);
    if (key === 0) return null;
    return { "#keyup": { key } };
  }

  function translateMouse(event) {
    const { x, y } = localXY(event);
    return {
      "#mouse": {
        buttons: browserButtonsToSDLMask(event.buttons),
        x,
        y,
      },
    };
  }

  function translateWheel(event) {
    return {
      "#wheel": {
        dx: wheelDeltaToStep(event.deltaX),
        dy: wheelDeltaToStep(event.deltaY),
      },
    };
  }

  function emit(payload) {
    if (!payload) return;
    showPayload(payload);
  }

  // listeners for the demo UI
  clearBtn.addEventListener("click", clearLog);
  focusBtn.addEventListener("click", () => surface.focus());

  surface.addEventListener("mousedown", (event) => {
    surface.focus();
    const { x, y } = localXY(event);
    moveDot(x, y);
    emit(translateMouse(event));
    event.preventDefault();
  });

  surface.addEventListener("mouseup", (event) => {
    const { x, y } = localXY(event);
    moveDot(x, y);
    emit(translateMouse(event));
    event.preventDefault();
  });

  surface.addEventListener("mousemove", (event) => {
    const payload = translateMouse(event);
    moveDot(payload["#mouse"].x, payload["#mouse"].y);
    emit(payload);
  });

  surface.addEventListener("wheel", (event) => {
    emit(translateWheel(event));
    event.preventDefault();
  }, { passive: false });

  surface.addEventListener("contextmenu", (event) => {
    event.preventDefault();
  });

  window.addEventListener("keydown", (event) => {
    if (document.activeElement !== surface) return;
    emit(translateKeyDown(event));
    event.preventDefault();
  });

  window.addEventListener("keyup", (event) => {
    if (document.activeElement !== surface) return;
    emit(translateKeyUp(event));
    event.preventDefault();
  });

  window.LysEventBridge = {
    jsKeyToSDL,
    browserButtonsToSDLMask,
    translateKeyDown,
    translateKeyUp,
    translateMouse,
    translateWheel,
  };

  appendLog("Ready. Click inside the surface to start.");
})();