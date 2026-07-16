#!/usr/bin/env bash
set -euo pipefail

APP_PROJECTS="${APP_PROJECTS:-}"
SERVICE_ROOT="${SERVICE_ROOT:-src/services}"
SHARED_ROOT="${SHARED_ROOT:-src/shared}"
CONFIGURATION="${CONFIGURATION:-Release}"
PROJECTS_FILE="$(mktemp)"

cleanup() {
  rm -f "$PROJECTS_FILE"
}
trap cleanup EXIT

{
  for csproj in $APP_PROJECTS; do printf '%s\n' "$csproj"; done
    for root in "$SERVICE_ROOT" "$SHARED_ROOT"; do
      [[ -d "$root" ]] || continue
      find "$root" \
        \( -name bin -o -name obj -o -name Debug -o -name debug -o -name Release -o -name release \
           -o -name publish -o -name publish-veracode -o -name veracode-scan -o -name veracode-results \
           -o -name TestResults -o -name .vs -o -name .git -o -name node_modules \) -type d -prune -o \
        -name "*.csproj" -type f -print
    done
  } | sort -u > "$PROJECTS_FILE"

if [[ ! -s "$PROJECTS_FILE" ]]; then
  echo "No .csproj files found. Set APP_PROJECTS and/or SERVICE_ROOT." >&2
  exit 1
fi

while read -r csproj; do
  dotnet restore "$csproj"
done < "$PROJECTS_FILE"

while read -r csproj; do
  dotnet build "$csproj" -c "$CONFIGURATION" --no-restore
done < "$PROJECTS_FILE"
