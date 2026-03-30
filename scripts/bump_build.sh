#!/bin/sh

set -eu

SCRIPT_DIR="$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)"
REPO_ROOT="$(CDPATH= cd -- "$SCRIPT_DIR/.." && pwd)"
PROJECT_FILE="$REPO_ROOT/kutuk.xcodeproj/project.pbxproj"

read_build_setting() {
  setting_name="$1"
  sed -n "s/^[[:space:]]*${setting_name} = \\(.*\\);/\\1/p" "$PROJECT_FILE" | head -n1
}

CURRENT_VERSION="$(read_build_setting MARKETING_VERSION)"
CURRENT_BUILD="$(read_build_setting CURRENT_PROJECT_VERSION)"
NEXT_BUILD=$((CURRENT_BUILD + 1))

"$SCRIPT_DIR/bump_version.sh" "$CURRENT_VERSION" "$NEXT_BUILD"
