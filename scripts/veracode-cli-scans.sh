#!/usr/bin/env bash
set -euo pipefail

VERACODE_BIN="${VERACODE_BIN:-veracode}"
RESULTS_DIR="${RESULTS_DIR:-veracode-results}"
IAC_DIR="${IAC_DIR:-infra}"

if [[ -n "${VERACODE_API_ID:-}" && -z "${VERACODE_API_KEY_ID:-}" ]]; then
  export VERACODE_API_KEY_ID="$VERACODE_API_ID"
fi

if [[ -n "${VERACODE_API_KEY:-}" && -z "${VERACODE_API_KEY_SECRET:-}" ]]; then
  export VERACODE_API_KEY_SECRET="$VERACODE_API_KEY"
fi

: "${VERACODE_API_KEY_ID:?Set VERACODE_API_KEY_ID or VERACODE_API_ID.}"
: "${VERACODE_API_KEY_SECRET:?Set VERACODE_API_KEY_SECRET or VERACODE_API_KEY.}"

if [[ ! -d "$IAC_DIR" ]]; then
  echo "IaC directory not found: $IAC_DIR" >&2
  exit 1
fi

mkdir -p "$RESULTS_DIR" "$HOME/.veracode"
chmod 700 "$HOME/.veracode"

# GitHub-hosted runners are ephemeral; auth comes from environment variables.
touch "$HOME/.veracode/veracode.yml"
chmod 600 "$HOME/.veracode/veracode.yml"

if ! command -v "$VERACODE_BIN" >/dev/null 2>&1 && [[ ! -x "$VERACODE_BIN" ]]; then
  curl -fsS https://tools.veracode.com/veracode-cli/install | sh
fi

if [[ -x "./veracode" ]]; then
  VERACODE_BIN="./veracode"
fi

"$VERACODE_BIN" version

"$VERACODE_BIN" scan \
  --source "$IAC_DIR" \
  --type directory \
  --format json \
  --output "$RESULTS_DIR/veracode-iac-results.json"
