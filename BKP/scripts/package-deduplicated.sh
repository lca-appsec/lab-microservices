#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ARTIFACTS="$ROOT_DIR/artifacts"
PUBLISH="$ROOT_DIR/.packaging/publish"
SCAN="$ROOT_DIR/.packaging/deduplicated"
SERVICES=(Service01.Api Service02.Api Service03.Api Service04.Api Service05.Api Service06.Api Service07.Api Service08.Api Service09.Api)

rm -rf "$PUBLISH" "$SCAN"
mkdir -p "$PUBLISH" "$SCAN/services" "$SCAN/shared" "$ARTIFACTS"

for SERVICE in "${SERVICES[@]}"; do
  SERVICE_PUBLISH="$PUBLISH/$SERVICE"

  dotnet publish "$ROOT_DIR/src/services/$SERVICE/$SERVICE.csproj" \
    -c Release \
    -f net8.0 \
    -o "$SERVICE_PUBLISH" \
    -p:UseAppHost=false

  mkdir -p "$SCAN/services/$SERVICE"

  cp "$SERVICE_PUBLISH/$SERVICE.dll" "$SCAN/services/$SERVICE/"
  cp "$SERVICE_PUBLISH/$SERVICE.pdb" "$SCAN/services/$SERVICE/" 2>/dev/null || true
  cp "$SERVICE_PUBLISH/$SERVICE.deps.json" "$SCAN/services/$SERVICE/" 2>/dev/null || true
  cp "$SERVICE_PUBLISH/$SERVICE.runtimeconfig.json" "$SCAN/services/$SERVICE/" 2>/dev/null || true

  find "$SERVICE_PUBLISH" -maxdepth 1 -type f \( -name "Shared.Module*.dll" -o -name "Shared.Module*.pdb" \) | while read -r FILE; do
    BASE="$(basename "$FILE")"
    if [[ ! -f "$SCAN/shared/$BASE" ]]; then
      cp "$FILE" "$SCAN/shared/$BASE"
    fi
  done
done

rm -f "$ARTIFACTS/veracode-deduplicated.zip"
cd "$SCAN"
zip -r -q "$ARTIFACTS/veracode-deduplicated.zip" .

echo "Created $ARTIFACTS/veracode-deduplicated.zip"
