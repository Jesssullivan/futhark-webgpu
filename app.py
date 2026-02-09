"""Futhark WebGPU Demo: Flask server with COOP/COEP headers.

Serves the Mandelbrot WebGPU demo with the required
Cross-Origin-Opener-Policy and Cross-Origin-Embedder-Policy
headers for SharedArrayBuffer support.

Usage:
    python app.py [--port 8000] [--host 0.0.0.0]
    flask --app app run --port 8000
"""

import argparse
import mimetypes
import os

from flask import Flask, send_from_directory

DEMO_ROOT = os.environ.get(
    "DEMO_ROOT",
    os.path.join(os.path.dirname(__file__), "examples", "sebastian-example"),
)

app = Flask(__name__, static_folder=None)

mimetypes.add_type("application/wasm", ".wasm")


@app.after_request
def add_coop_coep(response):
    response.headers["Cross-Origin-Opener-Policy"] = "same-origin"
    response.headers["Cross-Origin-Embedder-Policy"] = "credentialless"
    return response


@app.route("/healthz")
def healthz():
    return "OK", 200


@app.route("/")
def index():
    return send_from_directory(DEMO_ROOT, "index.html")


@app.route("/<path:filename>")
def static_files(filename):
    return send_from_directory(DEMO_ROOT, filename)


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Futhark WebGPU Flask demo")
    parser.add_argument("--port", type=int, default=8000)
    parser.add_argument("--host", default="0.0.0.0")
    args = parser.parse_args()

    print(f"Serving Mandelbrot demo at http://{args.host}:{args.port}/")
    print("COOP/COEP headers enabled for SharedArrayBuffer and WebGPU.")
    print("Open in Chrome 133+ / Firefox 141+ / Safari 26+")
    app.run(host=args.host, port=args.port)
