# dev-bootstrap-local-coding-agents
# -------------------------------------------------------------------------
# Bootstrap a fully-local coding agent on macOS. Interactively pick a
# backend (Ollama or LM Studio) and a model, then everything is installed,
# served, and wired into a self-contained qwen-code workspace.
#
#   just init ~/my-workspace                 # interactive: choose backend + model
#   just init ~/my-workspace ollama qwen     # non-interactive (backend + model key)
#   just init ~/my-workspace lmstudio gemma
#   just models                              # list the model catalog
#   just run ~/my-workspace                  # launch qwen in the workspace
#
# Apple Silicon -> MLX builds are used automatically; Intel -> GGUF.
# qwen-code runs under a pinned Node 22 (it breaks on Node >=24); use `just run`.
# The workspace gets its own ./.qwen/ config; global ~/.qwen is untouched.
# -------------------------------------------------------------------------

set shell := ["bash", "-uc"]

# ---- configuration ----
ollama_host   := "http://127.0.0.1:11434"
lmstudio_host := "http://127.0.0.1:1234"
sandbox       := "true"                       # sandbox agent tool exec (macOS Seatbelt)
force_fmt     := ""                           # "mlx" | "gguf" to override arch detection
default_dest  := env_var('HOME') / "qwen-coder-workspace"

# Show available recipes.
default:
    @just --list

# List the model catalog with sizes, quantization and parameters.
models:
    @bash scripts/lib/catalog.sh --list

# Full bootstrap. Interactive when backend/model are omitted.
init dest=default_dest backend='' model='':
    #!/usr/bin/env bash
    set -euo pipefail
    backend="$(bash scripts/lib/select-backend.sh '{{backend}}')"
    fmt="$(bash scripts/lib/arch.sh '{{force_fmt}}')"
    echo "Hardware $(uname -m) -> using $(echo "$fmt" | tr '[:lower:]' '[:upper:]') models."
    model_info="$(bash scripts/lib/select-model.sh "$backend" "$fmt" '{{model}}')"
    key="${model_info%%|*}"; model_id="${model_info##*|}"
    echo "▸ backend=$backend  model=$key  identifier=$model_id  format=$fmt"
    just --justfile "{{justfile()}}" install-deps "$backend"
    eval "$(bash scripts/lib/brew-env.sh)"   # put freshly-installed brew tools on PATH for the steps below
    just --justfile "{{justfile()}}" serve "$backend"
    eval "$(bash scripts/lib/backend.sh "$backend" '{{ollama_host}}' '{{lmstudio_host}}')"
    export HOST APIKEY LMS_BIN
    served="$(bash "scripts/backends/$backend/download.sh" "$model_id" "$fmt" "$key")"
    echo "✓ model is served as: $served"
    just --justfile "{{justfile()}}" configure '{{dest}}' "$backend" "$served"
    bash scripts/workspace/verify.sh "$served"
    echo ""
    echo "✅ Ready. Start coding with:"
    echo "     just run {{dest}}"

# Write the self-contained qwen-code config into <dest>/.qwen/ (+ QWEN.md).
configure dest backend served:
    #!/usr/bin/env bash
    set -euo pipefail
    b="$(bash scripts/lib/select-backend.sh '{{backend}}')"
    eval "$(bash scripts/lib/backend.sh "$b" '{{ollama_host}}' '{{lmstudio_host}}')"
    export HOST APIKEY
    bash scripts/workspace/configure.sh '{{dest}}' "$b" '{{served}}' '{{sandbox}}'

# Report the status of requirements for a backend (or all backends if omitted).
check backend='':
    #!/usr/bin/env bash
    set -uo pipefail
    eval "$(bash scripts/lib/brew-env.sh)"
    bash scripts/lib/check-base.sh
    b='{{backend}}'; [ "$b" = "lm-studio" ] && b="lmstudio"
    matched=0
    for dir in scripts/backends/*/; do
      name="$(basename "$dir")"
      if [ -z "$b" ] || [ "$b" = "$name" ]; then
        matched=1
        eval "$(bash scripts/lib/backend.sh "$name" '{{ollama_host}}' '{{lmstudio_host}}')"
        export HOST LMS_BIN
        bash "scripts/backends/$name/check.sh"
      fi
    done
    if [ -n "$b" ] && [ "$matched" -eq 0 ]; then
      echo "error: unknown backend '$b' (use ollama | lmstudio)" >&2
      exit 1
    fi

# Install any missing requirements for a backend (idempotent).
install-deps backend:
    #!/usr/bin/env bash
    set -euo pipefail
    b="$(bash scripts/lib/select-backend.sh '{{backend}}')"
    bash scripts/lib/install-base.sh
    eval "$(bash scripts/lib/brew-env.sh)"   # brew now installed; put it on PATH for the backend install below
    bash "scripts/backends/$b/install.sh"

# Start a backend's local server (idempotent; waits until reachable).
serve backend:
    #!/usr/bin/env bash
    set -euo pipefail
    eval "$(bash scripts/lib/brew-env.sh)"
    b="$(bash scripts/lib/select-backend.sh '{{backend}}')"
    eval "$(bash scripts/lib/backend.sh "$b" '{{ollama_host}}' '{{lmstudio_host}}')"
    export HOST LMS_BIN
    bash "scripts/backends/$b/serve.sh"

# Launch the qwen agent inside the workspace (runs under a qwen-compatible Node).
run dest=default_dest:
    #!/usr/bin/env bash
    set -euo pipefail
    eval "$(bash scripts/lib/brew-env.sh)"
    node_bin="$(bash scripts/lib/qwen-node.sh)" || { echo "✗ no qwen-compatible Node (node@22). Run: just install-deps <backend>" >&2; exit 1; }
    qwen_cli="$(bash scripts/lib/qwen-cli.sh)" || { echo "✗ qwen-code not installed. Run: just install-deps <backend>" >&2; exit 1; }
    cd "{{dest}}"
    exec "$node_bin" "$qwen_cli"

# Run the offline unit test suite (no network, no installs).
test:
    @bash tests/run.sh

# Remove only the generated qwen-code config files from <dest>/.qwen/ (leaves QWEN.md and any user-added files).
clean dest=default_dest:
    #!/usr/bin/env bash
    set -euo pipefail
    qwen_dir="{{dest}}/.qwen"
    rm -f "$qwen_dir/.env" "$qwen_dir/settings.json" "$qwen_dir/.bootstrapped"
    if [ -d "$qwen_dir" ] && [ -z "$(ls -A "$qwen_dir" 2>/dev/null)" ]; then
      rmdir "$qwen_dir"
      echo "✓ removed $qwen_dir"
    else
      echo "✓ removed generated files from $qwen_dir (directory kept — other files present)"
    fi
