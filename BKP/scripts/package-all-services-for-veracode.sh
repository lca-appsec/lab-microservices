#!/usr/bin/env bash
set -euo pipefail

SCAN_DIR="veracode-scan"
ZIP_FILE="veracode-upload.zip"

rm -rf "$SCAN_DIR" "$ZIP_FILE" publish
mkdir -p "$SCAN_DIR/services" "$SCAN_DIR/shared"

SERVICES=(
  "src/services/Service01.Api/Service01.Api.csproj"
  "src/services/Service02.Api/Service02.Api.csproj"
  "src/services/Service03.Api/Service03.Api.csproj"
  "src/services/Service04.Api/Service04.Api.csproj"
  "src/services/Service05.Api/Service05.Api.csproj"
  "src/services/Service06.Api/Service06.Api.csproj"
  "src/services/Service07.Api/Service07.Api.csproj"
  "src/services/Service08.Api/Service08.Api.csproj"
  "src/services/Service09.Api/Service09.Api.csproj"
)

for CSPROJ in "${SERVICES[@]}"; do
  SERVICE_NAME="$(basename "$(dirname "$CSPROJ")")"
  PUBLISH_DIR="publish/$SERVICE_NAME"

  dotnet publish "$CSPROJ" \
    -c Release \
    -f net8.0 \
    -o "$PUBLISH_DIR" \
    -p:UseAppHost=false

  mkdir -p "$SCAN_DIR/services/$SERVICE_NAME"

  cp "$PUBLISH_DIR/$SERVICE_NAME.dll" "$SCAN_DIR/services/$SERVICE_NAME/" || true
  cp "$PUBLISH_DIR/$SERVICE_NAME.pdb" "$SCAN_DIR/services/$SERVICE_NAME/" || true

  find "$PUBLISH_DIR" -maxdepth 1 -type f \( -name "Shared.*.dll" -o -name "Shared.*.pdb" -o -name "Gol.*.dll" -o -name "Gol.*.pdb" \) | while read -r file; do
    base="$(basename "$file")"
    if [ ! -f "$SCAN_DIR/shared/$base" ]; then
      cp "$file" "$SCAN_DIR/shared/$base"
    fi
  done
done

cd "$SCAN_DIR"
zip -r "../$ZIP_FILE" . \
  -x "Microsoft.*.dll" \
  -x "System.*.dll" \
  -x "Newtonsoft.Json.dll" \
  -x "*.deps.json" \
  -x "*.runtimeconfig.json" \
  -x "*.config" \
  -x "*.json" \
  -x "*.xml" \
  -x "*.md" \
  -x "*.log"