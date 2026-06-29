# dev-bootstrap-local-coding-agents

Bootstrap a fully-local coding agent on macOS with one command. Pick a backend
(Ollama or LM Studio) and a model; everything is installed, served, and wired
into a self-contained [qwen-code](https://github.com/QwenLM/qwen-code) workspace.

```bash
just init ~/my-workspace                 # interactive: choose backend + model
just init ~/my-workspace lmstudio qwen   # non-interactive (backend + model key)
cd ~/my-workspace && qwen
```

Apple Silicon pulls MLX builds automatically; Intel uses GGUF. The workspace gets
its own `./.qwen/` config — your global `~/.qwen` is never touched.

## Requirements

- macOS (Apple Silicon or Intel)
- [`just`](https://github.com/casey/just) — `brew install just`
- A backend: either [Ollama](https://ollama.com) or [LM Studio](https://lmstudio.ai)

`brew`, `node`, and `qwen-code` are installed automatically if missing.

## Quick start (LM Studio)

```bash
just models                              # list the model catalog
just check lmstudio                      # verify lms + server reachability
just init ~/my-workspace lmstudio qwen   # configure the workspace
cd ~/my-workspace && qwen                # start coding
```

If the requested model is **already loaded** in LM Studio, `init` reuses it and
downloads nothing.

## How it's structured

The justfile holds only thin recipes; each shells out to one small, focused,
independently testable script. There is no `case "$backend"` ladder duplicated
across recipes — backend metadata lives in exactly one place (`backend.sh`), and
per-backend behaviour is dispatched by convention: `backends/<name>/<verb>.sh`.

```
justfile ── thin recipes; each shells out to one focused script
│
├── scripts/lib/              shared, backend-agnostic helpers
│   ├── brew-env.sh           put Homebrew (Apple Silicon or Intel) on PATH
│   ├── arch.sh               CPU arch -> "mlx" | "gguf"
│   ├── catalog.sh            the model catalog (single source of truth)
│   ├── select-backend.sh     validate / prompt for the backend
│   ├── select-model.sh       resolve a catalog key -> backend model id
│   ├── backend.sh            backend -> HOST / APIKEY / LMS_BIN
│   ├── install-base.sh       ensure brew, node, qwen-code
│   └── check-base.sh         probe brew / node / qwen
│
├── scripts/backends/<name>/  one directory per backend (ollama, lmstudio)
│   ├── install.sh            install the backend
│   ├── serve.sh              start its server; wait until reachable
│   ├── download.sh           ensure the model is served (idempotent)
│   └── check.sh              probe backend binary + server
│
└── scripts/workspace/        the generated qwen-code workspace
    ├── configure.sh          write .qwen/.env + settings.json (+ QWEN.md)
    └── verify.sh             confirm the model answers at HOST/v1
```

`just init` decomposes the former monolithic recipe into these steps:

```
just init ~/ws lmstudio qwen
   │
   1. select-backend.sh   ──▶  lmstudio
   2. arch.sh             ──▶  mlx   (Apple Silicon; Intel -> gguf)
   3. select-model.sh     ──▶  qwen | qwen/qwen3.6-35b-a3b
   4. install-deps        ──▶  install-base.sh + backends/lmstudio/install.sh
   5. serve               ──▶  backends/lmstudio/serve.sh
   6. download.sh         ──▶  already loaded? reuse; else lms get + load
   7. configure.sh        ──▶  ~/ws/.qwen/{.env, settings.json}
   8. verify.sh           ──▶  GET HOST/v1/models
```

### The script contract

Scripts communicate over a small, explicit protocol so each can be run and
tested in isolation:

- **`backend.sh`** prints `HOST=…`, `APIKEY=…`, `LMS_BIN=…`; callers do
  `eval "$(bash scripts/lib/backend.sh <backend> …)"` and `export` them.
- **`brew-env.sh`** prints `brew shellenv` output (or nothing); callers
  `eval` it to put brew tools on PATH for the next step.
- **`select-*.sh`** print their single result to stdout (prompts go to stderr).
- **`download.sh`** prints the *served* model id to stdout; the caller captures
  it with `$(…)` and feeds it to `configure.sh`.

## Adding a backend

Create `scripts/backends/<name>/` with `install.sh`, `serve.sh`, `download.sh`,
and `check.sh`, then add a `case` arm to `scripts/lib/backend.sh` and
`scripts/lib/select-backend.sh`. `check` auto-discovers the new directory; no
recipe changes needed.

## Adding a model

Add one pipe-delimited row to `_rows()` in `scripts/lib/catalog.sh`:

```
key | label | params | size | quant | ollama-mlx-tag | ollama-gguf-tag | lmstudio-name
```

The `lmstudio-name` must match the `id` shown by
`curl -s http://127.0.0.1:1234/v1/models` for the reuse-without-download path to
work.

## Recipes

| Recipe | Purpose |
|--------|---------|
| `just init <dest> [backend] [model]` | Full bootstrap (interactive if args omitted) |
| `just models` | List the model catalog |
| `just check [backend]` | Report requirement status for one/all backends |
| `just install-deps <backend>` | Install missing requirements (idempotent) |
| `just serve <backend>` | Start the backend's server |
| `just configure <dest> <backend> <served>` | Write the workspace config only |
| `just run [dest]` | Launch qwen in the workspace |
| `just test` | Run the offline unit test suite |
| `just clean [dest]` | Remove only the generated config files |

## Testing

```bash
just test          # or: bash tests/run.sh
```

The suite is offline (no network, no installs): it exercises `arch.sh`,
`catalog.sh`, `select-backend.sh`, `backend.sh`, `select-model.sh`, and the
`configure.sh` clobber guard. CI runs it on macOS plus `shellcheck` on Linux.

## Safety notes

- `configure` refuses to overwrite a `.qwen/` it did not create (it writes a
  `.bootstrapped` marker and checks for it), so it won't clobber your own config.
- `clean` removes only the generated files (`.env`, `settings.json`,
  `.bootstrapped`); your `QWEN.md` and any other files are left in place.
- The catalog ships with `qwen` and `gemma` LM Studio names verified against a
  live install; `north` and `nemotron` are placeholders — adjust them to ids
  that exist in your registry before use.
