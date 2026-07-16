#!/usr/bin/env bash
set -euo pipefail

LABS_DIR="/Users/luis.araujo/Documents/labs"
UPLOAD_ZIP="/Users/luis.araujo/Documents/Codex/2026-06-23/teste-esse-endpoint-e-me-dica/outputs/verademo-dotnetcore-upload.zip"

if [[ -z "${VERACODE_API_ID:-}" || -z "${VERACODE_API_KEY:-}" ]]; then
  echo "Set VERACODE_API_ID and VERACODE_API_KEY before running." >&2
  exit 1
fi

java -jar "$LABS_DIR/VeracodeJavaAPI.jar" \
  -vid "$VERACODE_API_ID" \
  -vkey "$VERACODE_API_KEY" \
  -action uploadandscan \
  -maxretrycount 1 \
  -createprofile true \
  -version "test-wrapper-appid-scan" \
  -filepath "$UPLOAD_ZIP" \
  -scanallnonfataltoplevelmodules true \
  -includenewmodules true \
  -appname "verademo-dotnet"
