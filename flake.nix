{
  description = "Futhark WebGPU Demos - Mandelbrot set rendered via WebGPU compute shaders";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
    nix2container = {
      url = "github:nlewo/nix2container";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, flake-utils, nix2container }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = import nixpkgs {
          inherit system;
          overlays = [
            # Fix emscripten 4.0.21: --no-stack-first flag not supported by bundled LLVM 21
            (final: prev: {
              emscripten = prev.emscripten.overrideAttrs (old: {
                postPatch = (old.postPatch or "") + ''
                  sed -i "s/cmd.append('--no-stack-first')/pass/" tools/building.py
                '';
              });
            })
          ];
        };
        n2c = nix2container.packages.${system}.nix2container;

        # Build the Mandelbrot WASM artifacts
        # Requires futhark with WebGPU backend (from diku-dk/futhark webgpu branch)
        mandelbrot-wasm = pkgs.stdenv.mkDerivation {
          pname = "mandelbrot-webgpu";
          version = "0.1.0";
          src = ./examples/sebastian-example;

          nativeBuildInputs = with pkgs; [
            emscripten
          ];

          # Futhark must be pre-compiled and available in PATH
          # For CI, install from: cabal install --installdir=$out/bin
          buildPhase = ''
            export HOME=$TMPDIR
            export EM_CACHE=$TMPDIR/.emscripten_cache

            # If futhark is available, compile; otherwise expect pre-built artifacts
            if command -v futhark &>/dev/null; then
              futhark webgpu --library -o sebastian sebastian.fut
            else
              echo "WARNING: futhark not in PATH, expecting pre-built artifacts"
            fi
          '';

          installPhase = ''
            mkdir -p $out
            cp -r *.js *.wasm *.json *.html 2>/dev/null || true
            cp glue.js $out/ 2>/dev/null || true
          '';
        };
      in
      {
        # Development shell with Futhark WebGPU build environment
        devShells.default = pkgs.mkShell {
          packages = with pkgs; [
            emscripten
            python3  # For http.server
            caddy     # For COOP/COEP serving
            just      # Developer commands
          ];

          EM_CACHE = "$PWD/.emscripten_cache";

          shellHook = ''
            echo "Futhark WebGPU Demos"
            echo "===================="
            echo ""
            echo "Prerequisites: futhark with WebGPU backend in PATH"
            echo ""
            echo "Commands:"
            echo "  just build    - Compile Mandelbrot to WebGPU"
            echo "  just serve    - Serve with python3 http.server"
            echo "  just caddy    - Serve with Caddy (COOP/COEP headers)"
            echo ""
          '';
        };

        # ================================================================
        # OCI Container Images via nix2container
        # ================================================================

        # Caddy container serving the Mandelbrot demo
        # Provides COOP/COEP headers required for SharedArrayBuffer
        packages.container-caddy = n2c.buildImage {
          name = "futhark-webgpu-caddy";
          tag = self.rev or "dev";

          copyToRoot = pkgs.buildEnv {
            name = "caddy-root";
            paths = with pkgs; [ caddy cacert ];
            pathsToLink = [ "/bin" "/etc" ];
          };

          config = {
            ExposedPorts = {
              "8080/tcp" = {};
            };
            Cmd = [ "${pkgs.caddy}/bin/caddy" "run" "--config" "/etc/caddy/Caddyfile" ];
          };
        };

        # Flask container serving the Mandelbrot demo
        packages.container-flask = n2c.buildImage {
          name = "futhark-webgpu-flask";
          tag = self.rev or "dev";

          layers = [
            (n2c.buildLayer {
              deps = with pkgs; [
                (python3.withPackages (ps: [ ps.flask ]))
                cacert
              ];
            })
          ];

          copyToRoot = pkgs.buildEnv {
            name = "flask-root";
            paths = with pkgs; [
              (python3.withPackages (ps: [ ps.flask ]))
              cacert
            ];
            pathsToLink = [ "/bin" "/lib" "/etc" ];
          };

          config = {
            ExposedPorts = {
              "8080/tcp" = {};
            };
            WorkingDir = "/app";
            Cmd = [
              "${pkgs.python3.withPackages (ps: [ ps.flask ])}/bin/python"
              "app.py"
            ];
          };
        };

        # Static container (Caddy serving pre-built files, no reverse proxy)
        packages.container-static = n2c.buildImage {
          name = "futhark-webgpu-static";
          tag = self.rev or "dev";

          copyToRoot = pkgs.buildEnv {
            name = "static-root";
            paths = with pkgs; [ caddy cacert ];
            pathsToLink = [ "/bin" "/etc" ];
          };

          config = {
            ExposedPorts = {
              "8080/tcp" = {};
            };
            Cmd = [ "${pkgs.caddy}/bin/caddy" "file-server" "--root" "/srv" "--listen" ":8080" ];
          };
        };
      }
    );
}
