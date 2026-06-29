#!/usr/bin/env bash
# Offline unit tests for the bootstrap scripts.
# No network, no installs, no real backends — only the pure-logic helpers and
# the workspace config writer (which only touches a throwaway temp dir).
#
# Run:  bash tests/run.sh      (or: just test)
# Exit: 0 if all pass, 1 otherwise.
#
# Compatible with macOS's default bash 3.2.
set -uo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT" || exit 1

pass=0
fail=0
TMPDIRS=()

cleanup() { for d in "${TMPDIRS[@]:-}"; do [ -n "$d" ] && rm -rf "$d"; done; }
trap cleanup EXIT

ok()  { printf "  ok   %s\n" "$1"; pass=$((pass + 1)); }
bad() { printf "  FAIL %s\n" "$1"; printf "       %s\n" "$2"; fail=$((fail + 1)); }

# assert_eq <name> <expected> <actual>
assert_eq() {
  if [ "$2" = "$3" ]; then ok "$1"; else bad "$1" "expected [$2] got [$3]"; fi
}

# assert_contains <name> <haystack> <needle>
assert_contains() {
  case "$2" in
    *"$3"*) ok "$1" ;;
    *)      bad "$1" "output does not contain [$3]" ;;
  esac
}

# assert_status <name> <expected_code> <cmd...>
assert_status() {
  local name="$1" want="$2"; shift 2
  "$@" >/dev/null 2>&1
  local got=$?
  if [ "$got" -eq "$want" ]; then ok "$name"; else bad "$name" "expected exit $want got $got"; fi
}

section() { printf "\n%s\n" "$1"; }

# ---------------------------------------------------------------------------
section "arch.sh"
assert_eq  "force mlx wins"          "mlx"  "$(bash scripts/lib/arch.sh mlx)"
assert_eq  "force gguf wins"         "gguf" "$(bash scripts/lib/arch.sh gguf)"
case "$(bash scripts/lib/arch.sh)" in
  mlx|gguf) ok "auto-detect yields mlx|gguf" ;;
  *)        bad "auto-detect yields mlx|gguf" "got [$(bash scripts/lib/arch.sh)]" ;;
esac

# ---------------------------------------------------------------------------
section "catalog.sh"
rows="$(bash scripts/lib/catalog.sh --parse)"
assert_eq  "--parse emits 4 rows"    "4" "$(printf '%s\n' "$rows" | grep -c '|')"
badrow=0
while IFS= read -r line; do
  [ -z "$line" ] && continue
  pipes="${line//[^|]}"
  [ "${#pipes}" -eq 7 ] || badrow=1
done <<EOF
$rows
EOF
assert_eq  "every row has 7 pipes"   "0" "$badrow"
assert_contains "--list has header"  "$(bash scripts/lib/catalog.sh --list)" "KEY"
assert_status "unknown arg fails"    1 bash scripts/lib/catalog.sh bogus

# ---------------------------------------------------------------------------
section "select-backend.sh"
assert_eq  "ollama passthrough"      "ollama"   "$(bash scripts/lib/select-backend.sh ollama)"
assert_eq  "lmstudio passthrough"    "lmstudio" "$(bash scripts/lib/select-backend.sh lmstudio)"
assert_eq  "lm-studio normalises"    "lmstudio" "$(bash scripts/lib/select-backend.sh lm-studio)"
assert_status "unknown backend fails" 1 bash scripts/lib/select-backend.sh bogus

# ---------------------------------------------------------------------------
section "backend.sh"
ob="$(bash scripts/lib/backend.sh ollama http://o:1 http://l:2)"
assert_contains "ollama HOST"        "$ob" "HOST=http://o:1"
assert_contains "ollama APIKEY"      "$ob" "APIKEY=ollama"
assert_contains "ollama empty LMS"   "$ob" "LMS_BIN="
lb="$(bash scripts/lib/backend.sh lmstudio http://o:1 http://l:2)"
assert_contains "lmstudio HOST"      "$lb" "HOST=http://l:2"
assert_contains "lmstudio APIKEY"    "$lb" "APIKEY=lm-studio"
assert_status "unknown backend fails" 1 bash scripts/lib/backend.sh bogus http://o http://l

# ---------------------------------------------------------------------------
section "select-model.sh (incl. fix 4: ollama is GGUF-only)"
assert_eq  "ollama+gguf -> gguf tag" "qwen|qwen3.6:35b" "$(bash scripts/lib/select-model.sh ollama gguf qwen)"
assert_eq  "ollama+mlx  -> gguf tag" "qwen|qwen3.6:35b" "$(bash scripts/lib/select-model.sh ollama mlx qwen)"
assert_eq  "lmstudio qwen name"      "qwen|qwen/qwen3.6-35b-a3b" "$(bash scripts/lib/select-model.sh lmstudio mlx qwen)"
assert_eq  "lmstudio gemma name"     "gemma|gemma-4-e2b-it"      "$(bash scripts/lib/select-model.sh lmstudio gguf gemma)"
assert_status "unknown model fails"  1 bash scripts/lib/select-model.sh ollama gguf bogus

# ---------------------------------------------------------------------------
section "configure.sh (clobber guard)"
d1="$(mktemp -d)"; TMPDIRS+=("$d1")
HOST="http://h:1" APIKEY="k" bash scripts/workspace/configure.sh "$d1" ollama mymodel true >/dev/null 2>&1
st=$?
assert_eq  "fresh write succeeds"    "0" "$st"
if [ -f "$d1/.qwen/.env" ];          then ok "writes .env";          else bad "writes .env" "missing"; fi
if [ -f "$d1/.qwen/settings.json" ]; then ok "writes settings.json"; else bad "writes settings.json" "missing"; fi
if [ -f "$d1/.qwen/.bootstrapped" ]; then ok "writes marker";        else bad "writes marker" "missing"; fi

# Re-run on our own marked dir must succeed (idempotent update).
HOST="http://h:1" APIKEY="k" bash scripts/workspace/configure.sh "$d1" ollama mymodel true >/dev/null 2>&1
assert_eq  "re-run on marked dir ok" "0" "$?"

# Foreign config (no marker) must be refused.
d2="$(mktemp -d)"; TMPDIRS+=("$d2")
mkdir -p "$d2/.qwen"
printf 'OPENAI_API_KEY=theirs\n' > "$d2/.qwen/.env"
HOST="http://h:1" APIKEY="k" bash scripts/workspace/configure.sh "$d2" ollama mymodel true >/dev/null 2>&1
assert_eq  "refuses foreign config"  "1" "$?"
assert_contains "foreign .env untouched" "$(cat "$d2/.qwen/.env")" "theirs"

# ---------------------------------------------------------------------------
printf "\n----\n%d passed, %d failed\n" "$pass" "$fail"
[ "$fail" -eq 0 ]
