#!/usr/bin/env bash
set -euo pipefail

if [[ $# -lt 1 || $# -gt 2 ]]; then
  echo "usage: BOB=/path/to/bob.jar $0 <platform> [output-dir]" >&2
  exit 2
fi
if [[ -z "${BOB:-}" ]]; then
  echo "BOB must point to a Defold Bob JAR" >&2
  exit 2
fi
if [[ ! -f "$BOB" ]]; then
  echo "Bob JAR not found: $BOB" >&2
  exit 2
fi

platform="$1"
output_dir="${2:-dist/$platform}"
java_cmd="${JAVA:-java}"
mkdir -p "$output_dir"
project_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$project_root"
exec "$java_cmd" -jar "$BOB" --archive --platform "$platform" --architectures "$platform" \
  --root "$project_root" --output "build/$platform" --bundle-output "$output_dir" \
  resolve distclean build bundle
