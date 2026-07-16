#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

for ZIP in "$ROOT_DIR/artifacts/veracode-duplicated.zip" "$ROOT_DIR/artifacts/veracode-deduplicated.zip"; do
  if [[ ! -f "$ZIP" ]]; then
    echo "Missing $ZIP"
    continue
  fi

  echo
  echo "$(basename "$ZIP")"
  echo "Total DLL entries: $(unzip -Z1 "$ZIP" | grep -E '\.dll$' | wc -l | tr -d ' ')"
  echo "Unique DLL names:  $(unzip -Z1 "$ZIP" | grep -E '\.dll$' | sed 's#.*/##' | sort -u | wc -l | tr -d ' ')"
  echo "Shared DLL entries: $(unzip -Z1 "$ZIP" | grep -E 'Shared\.Module.*\.dll$' | wc -l | tr -d ' ')"
done
