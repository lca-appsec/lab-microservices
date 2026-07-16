#!/usr/bin/env bash
set -euo pipefail

SERVICE_ROOT="${SERVICE_ROOT:-src/services}"
APP_PROJECTS="${APP_PROJECTS:-}"
REPOSITORY_NAME="$(basename "$(pwd)")"
IMAGE_PREFIX="${IMAGE_PREFIX:-$REPOSITORY_NAME}"
IMAGE_TAG="${IMAGE_TAG:-local}"
OUTPUT_FILE="${OUTPUT_FILE:-docker-images.txt}"
TARGET_FRAMEWORK="${TARGET_FRAMEWORK:-net8.0}"
IMAGE_PREFIX="$(printf '%s' "$IMAGE_PREFIX" | tr '[:upper:]' '[:lower:]')"

get_assembly_name() {
  local csproj="$1"
  local assembly_name

  assembly_name="$(sed -nE 's:.*<AssemblyName>([^<]+)</AssemblyName>.*:\1:p' "$csproj" | head -1)"

  if [[ -z "$assembly_name" ]]; then
    assembly_name="$(basename "$csproj" .csproj)"
  fi

  printf '%s\n' "$assembly_name"
}

rm -f "$OUTPUT_FILE"

{
  for csproj in $APP_PROJECTS; do printf '%s\n' "$csproj"; done
  if [[ -d "$SERVICE_ROOT" ]]; then
    find "$SERVICE_ROOT" \
      \( -name bin -o -name obj -o -name Debug -o -name debug -o -name Release -o -name release \
         -o -name publish -o -name publish-veracode -o -name veracode-scan -o -name veracode-results \
         -o -name TestResults -o -name .vs -o -name .git -o -name node_modules \) -type d -prune -o \
      -name "*.csproj" -type f -print
  fi
} | sort -u | while read -r CSPROJ; do
  SERVICE_DIR="$(dirname "$CSPROJ")"
  SERVICE_NAME="$(basename "$SERVICE_DIR")"
  SERVICE_ASSEMBLY="$(get_assembly_name "$CSPROJ")"
  DOCKERFILE="$SERVICE_DIR/Dockerfile"
  IMAGE_NAME="$(printf '%s' "$SERVICE_NAME" | tr '[:upper:]' '[:lower:]')"
  FULL_IMAGE_NAME="$IMAGE_PREFIX/$IMAGE_NAME:$IMAGE_TAG"

  if [[ ! -f "$DOCKERFILE" ]]; then
    echo "Missing Dockerfile for $SERVICE_NAME at $DOCKERFILE" >&2
    exit 1
  fi

  docker build \
    --file "$DOCKERFILE" \
    --build-arg "SERVICE_PROJECT=$CSPROJ" \
    --build-arg "SERVICE_ASSEMBLY=$SERVICE_ASSEMBLY" \
    --build-arg "TARGET_FRAMEWORK=$TARGET_FRAMEWORK" \
    --tag "$FULL_IMAGE_NAME" \
    .

  printf '%s\n' "$FULL_IMAGE_NAME" >> "$OUTPUT_FILE"
done
