#!/usr/bin/env bash
set -euo pipefail

APP_PROJECTS="${APP_PROJECTS:-}"
SERVICE_ROOT="${SERVICE_ROOT:-src/services}"
SHARED_ROOT="${SHARED_ROOT:-src/shared}"
TARGET_FRAMEWORK="${TARGET_FRAMEWORK:-net8.0}"
CONFIGURATION="${CONFIGURATION:-Release}"
ZIP_FILE="${ZIP_FILE:-veracode-upload.zip}"

PUBLISH_DIR="publish-veracode"
SCAN_DIR="veracode-scan"
EVIDENCE_DIR="veracode-evidence"
PROJECTS_FILE="$(mktemp)"
SHARED_PROJECTS_FILE="$(mktemp)"
ASSEMBLIES_FILE="$(mktemp)"
COPIED_FILES="$(mktemp)"

cleanup() {
  rm -f "$PROJECTS_FILE" "$SHARED_PROJECTS_FILE" "$ASSEMBLIES_FILE" "$COPIED_FILES"
}
trap cleanup EXIT

find_csproj() {
  local root="$1"
  [[ -d "$root" ]] || return 0
  find "$root" \
    \( -name bin -o -name obj -o -name Debug -o -name debug -o -name Release -o -name release \
       -o -name publish -o -name publish-veracode -o -name veracode-scan -o -name veracode-results \
       -o -name TestResults -o -name .vs -o -name .git -o -name node_modules \) -type d -prune -o \
    -name "*.csproj" -type f -print
}

assembly_name() {
  local csproj="$1"
  local name
  name="$(sed -nE 's:.*<AssemblyName>([^<]+)</AssemblyName>.*:\1:p' "$csproj" | head -1)"
  printf '%s\n' "${name:-$(basename "$csproj" .csproj)}"
}

copy_once() {
  local source="$1"
  local target_dir="$2"
  local name
  local target

  name="$(basename "$source")"
  target="$target_dir/$name"

  if [[ -f "$source" ]] && ! grep -Fxq "$name" "$COPIED_FILES"; then
    cp "$source" "$target"
    printf '%s\n' "$name" >> "$COPIED_FILES"
  fi
}

{
  for csproj in $APP_PROJECTS; do printf '%s\n' "$csproj"; done
  find_csproj "$SERVICE_ROOT"
} | sort -u > "$PROJECTS_FILE"

find_csproj "$SHARED_ROOT" | sort -u > "$SHARED_PROJECTS_FILE"

if [[ ! -s "$PROJECTS_FILE" ]]; then
  echo "No API .csproj found. Set APP_PROJECTS and/or SERVICE_ROOT." >&2
  exit 1
fi

{
  cat "$PROJECTS_FILE"
  cat "$SHARED_PROJECTS_FILE"
} | sort -u | while read -r csproj; do
  assembly_name "$csproj"
done | sort -u > "$ASSEMBLIES_FILE"

rm -rf "$PUBLISH_DIR" "$SCAN_DIR" "$EVIDENCE_DIR" "$ZIP_FILE"
mkdir -p "$SCAN_DIR/services" "$SCAN_DIR/shared"
mkdir -p "$EVIDENCE_DIR"

cp "$PROJECTS_FILE" "$EVIDENCE_DIR/service-projects.txt"
cp "$SHARED_PROJECTS_FILE" "$EVIDENCE_DIR/shared-projects.txt"
cp "$ASSEMBLIES_FILE" "$EVIDENCE_DIR/internal-assemblies.txt"

while read -r csproj; do
  service_name="$(assembly_name "$csproj")"
  out="$PUBLISH_DIR/$service_name"

  dotnet publish "$csproj" -c "$CONFIGURATION" -f "$TARGET_FRAMEWORK" -o "$out" -p:UseAppHost=false

  mkdir -p "$SCAN_DIR/services/$service_name"
  copy_once "$out/$service_name.dll" "$SCAN_DIR/services/$service_name"
  copy_once "$out/$service_name.pdb" "$SCAN_DIR/services/$service_name"

  while read -r assembly; do
    [[ "$assembly" == "$service_name" ]] && continue
    copy_once "$out/$assembly.dll" "$SCAN_DIR/shared"
    copy_once "$out/$assembly.pdb" "$SCAN_DIR/shared"
  done < "$ASSEMBLIES_FILE"
done < "$PROJECTS_FILE"

while read -r csproj; do
  shared_name="$(assembly_name "$csproj")"
  out="$PUBLISH_DIR/shared/$shared_name"

  dotnet publish "$csproj" -c "$CONFIGURATION" -f "$TARGET_FRAMEWORK" -o "$out" -p:UseAppHost=false

  copy_once "$out/$shared_name.dll" "$SCAN_DIR/shared"
  copy_once "$out/$shared_name.pdb" "$SCAN_DIR/shared"
done < "$SHARED_PROJECTS_FILE"

find "$SCAN_DIR" -type f ! \( -name "*.dll" -o -name "*.pdb" \) -delete
find "$SCAN_DIR" -mindepth 1 \
  \( -name bin -o -name obj -o -name Debug -o -name debug -o -name Release -o -name release \
     -o -name publish -o -name publish-veracode -o -name veracode-results \
     -o -name TestResults -o -name .vs -o -name .git -o -name node_modules \) -type d -prune -exec rm -rf {} +
find "$SCAN_DIR" -type d -empty -delete
(cd "$SCAN_DIR" && find . -type f | sort) > "$EVIDENCE_DIR/sast-package-files.txt"
sed 's#.*/##' "$EVIDENCE_DIR/sast-package-files.txt" | sort > "$EVIDENCE_DIR/sast-package-file-names.txt"
uniq -d "$EVIDENCE_DIR/sast-package-file-names.txt" > "$EVIDENCE_DIR/duplicate-file-names.txt"
grep -E '/(bin|obj|Debug|debug|Release|release|publish|publish-veracode|veracode-results|TestResults|\.vs|\.git|node_modules)/' "$EVIDENCE_DIR/sast-package-files.txt" > "$EVIDENCE_DIR/excluded-path-violations.txt" || true

if [[ -s "$EVIDENCE_DIR/duplicate-file-names.txt" ]]; then
  echo "Duplicated files detected in SAST package:" >&2
  cat "$EVIDENCE_DIR/duplicate-file-names.txt" >&2
  exit 1
fi

if [[ -s "$EVIDENCE_DIR/excluded-path-violations.txt" ]]; then
  echo "Excluded paths detected in SAST package:" >&2
  cat "$EVIDENCE_DIR/excluded-path-violations.txt" >&2
  exit 1
fi

(
  cd "$SCAN_DIR"
  zip -rq "../$ZIP_FILE" . \
    -x "Microsoft.*.dll" "System.*.dll" "Newtonsoft.Json.dll" \
    -x "*.deps.json" "*.runtimeconfig.json" "*.json" "*.xml" "*.config" "*.log" "*.md" \
    -x "*/bin/*" "*/obj/*" "*/Debug/*" "*/debug/*" "*/Release/*" "*/release/*" \
    -x "*/publish/*" "*/publish-veracode/*" "*/veracode-scan/*" "*/veracode-results/*" \
    -x "*/TestResults/*" "*/.vs/*" "*/.git/*" "*/node_modules/*"
)

project_count="$(wc -l < "$PROJECTS_FILE" | tr -d ' ')"
shared_count="$(wc -l < "$SHARED_PROJECTS_FILE" | tr -d ' ')"
echo "Created $ZIP_FILE with $project_count API project(s) and $shared_count shared project(s)."
echo "Evidence written to $EVIDENCE_DIR/."
