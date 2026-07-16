#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ARTIFACTS="$ROOT_DIR/artifacts"
WORK="$ROOT_DIR/.packaging/duplicated"
SERVICES=(Service01.Api Service02.Api Service03.Api Service04.Api Service05.Api Service06.Api Service07.Api Service08.Api Service09.Api)

rm -rf "$WORK"
mkdir -p "$WORK" "$ARTIFACTS"

for SERVICE in "${SERVICES[@]}"; do
  dotnet publish "$ROOT_DIR/src/services/$SERVICE/$SERVICE.csproj" \
    -c Release \
    -f net8.0 \
    -o "$WORK/$SERVICE" \
    -p:UseAppHost=false
done

rm -f "$ARTIFACTS/veracode-duplicated.zip"
cd "$WORK"
zip -r -q "$ARTIFACTS/veracode-duplicated.zip" .

echo "Created $ARTIFACTS/veracode-duplicated.zip"
