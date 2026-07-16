#!/usr/bin/env bash
set -euo pipefail

if [[ $# -ne 1 ]]; then
  echo "Usage: $0 <ServiceName>" >&2
  echo "Example: $0 Service01.Api" >&2
  exit 1
fi

SERVICE="$1"
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SERVICE_PROJECT="$ROOT_DIR/src/services/$SERVICE/$SERVICE.csproj"
PUBLISH_DIR="$ROOT_DIR/.packaging/github/$SERVICE/publish"
SCAN_DIR="$ROOT_DIR/.packaging/github/$SERVICE/scan"
ARTIFACTS_DIR="$ROOT_DIR/artifacts"
ZIP_FILE="$ARTIFACTS_DIR/$SERVICE-veracode-upload.zip"

if [[ ! -f "$SERVICE_PROJECT" ]]; then
  echo "Service project not found: $SERVICE_PROJECT" >&2
  exit 1
fi

rm -rf "$PUBLISH_DIR" "$SCAN_DIR"
mkdir -p "$SCAN_DIR/service" "$SCAN_DIR/shared" "$ARTIFACTS_DIR"

dotnet publish "$SERVICE_PROJECT" \
  -c Release \
  -f net8.0 \
  -o "$PUBLISH_DIR" \
  -p:UseAppHost=false \
  --no-restore

cp "$PUBLISH_DIR/$SERVICE.dll" "$SCAN_DIR/service/"
cp "$PUBLISH_DIR/$SERVICE.pdb" "$SCAN_DIR/service/" 2>/dev/null || true
cp "$PUBLISH_DIR/$SERVICE.deps.json" "$SCAN_DIR/service/" 2>/dev/null || true
cp "$PUBLISH_DIR/$SERVICE.runtimeconfig.json" "$SCAN_DIR/service/" 2>/dev/null || true

find "$PUBLISH_DIR" -maxdepth 1 -type f \( -name "Shared.Module*.dll" -o -name "Shared.Module*.pdb" \) | while read -r file; do
  cp "$file" "$SCAN_DIR/shared/"
done

rm -f "$ZIP_FILE"
(
  cd "$SCAN_DIR"
  zip -r -q "$ZIP_FILE" .
)

echo "$ZIP_FILE"
