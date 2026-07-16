#!/usr/bin/env bash
set -euo pipefail

APP_PROJECTS="${APP_PROJECTS:-}"
SERVICE_ROOT="${SERVICE_ROOT:-src/services}"
SHARED_ROOT="${SHARED_ROOT:-src/shared}"
TARGET_FRAMEWORK="${TARGET_FRAMEWORK:-net8.0}"
SCA_DIR="${SCA_DIR:-sca-scan}"
EVIDENCE_DIR="${SCA_EVIDENCE_DIR:-sca-evidence}"
PROJECTS_FILE="$(mktemp)"
ALL_PACKAGES_FILE="$(mktemp)"
PACKAGES_FILE="$(mktemp)"

cleanup() {
  rm -f "$PROJECTS_FILE" "$ALL_PACKAGES_FILE" "$PACKAGES_FILE"
}
trap cleanup EXIT

find_csproj() {
  local root="$1"
  [[ -d "$root" ]] || return 0

  find "$root" \
    \( -name bin -o -name obj -o -name Debug -o -name debug -o -name Release -o -name release \
       -o -name publish -o -name publish-veracode -o -name veracode-scan -o -name veracode-results \
       -o -name sca-scan -o -name TestResults -o -name .vs -o -name .git -o -name node_modules \) -type d -prune -o \
    -name "*.csproj" -type f -print
}

{
  for csproj in $APP_PROJECTS; do printf '%s\n' "$csproj"; done
  find_csproj "$SERVICE_ROOT"
  find_csproj "$SHARED_ROOT"
} | sort -u > "$PROJECTS_FILE"

if [[ ! -s "$PROJECTS_FILE" ]]; then
  echo "No .csproj files found for SCA aggregation." >&2
  exit 1
fi

while read -r csproj; do
  sed -nE 's/.*<PackageReference[^>]*Include="([^"]+)"[^>]*Version="([^"]+)".*/\1|\2/p' "$csproj"
done < "$PROJECTS_FILE" > "$ALL_PACKAGES_FILE"

awk -F'|' '!seen[$1]++' "$ALL_PACKAGES_FILE" | sort > "$PACKAGES_FILE"

if [[ ! -s "$PACKAGES_FILE" ]]; then
  echo "No PackageReference entries found for SCA aggregation." >&2
  exit 1
fi

rm -rf "$SCA_DIR"
mkdir -p "$SCA_DIR" "$EVIDENCE_DIR"

cp "$PROJECTS_FILE" "$EVIDENCE_DIR/sca-projects.txt"
cp "$PACKAGES_FILE" "$EVIDENCE_DIR/sca-packages.txt"

{
  printf '<Project Sdk="Microsoft.NET.Sdk">\n'
  printf '  <PropertyGroup>\n'
  printf '    <TargetFramework>%s</TargetFramework>\n' "$TARGET_FRAMEWORK"
  printf '  </PropertyGroup>\n'
  printf '  <ItemGroup>\n'
  while IFS='|' read -r package version; do
    printf '    <PackageReference Include="%s" Version="%s" />\n' "$package" "$version"
  done < "$PACKAGES_FILE"
  printf '  </ItemGroup>\n'
  printf '</Project>\n'
} > "$SCA_DIR/VeracodeSca.Aggregate.csproj"

echo "Created $SCA_DIR/VeracodeSca.Aggregate.csproj from $(wc -l < "$PROJECTS_FILE" | tr -d ' ') project(s)."
echo "Aggregated $(wc -l < "$PACKAGES_FILE" | tr -d ' ') unique PackageReference item(s)."
