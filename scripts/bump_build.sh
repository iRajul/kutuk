#!/bin/sh

set -eu

SCRIPT_DIR="$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)"
REPO_ROOT="$(CDPATH= cd -- "$SCRIPT_DIR/.." && pwd)"
PROJECT_FILE="$REPO_ROOT/kutuk.xcodeproj/project.pbxproj"

CURRENT_VERSION="$(rg -o 'MARKETING_VERSION = [^;]+' "$PROJECT_FILE" | head -n1 | sed 's/MARKETING_VERSION = //')"
CURRENT_BUILD="$(rg -o 'CURRENT_PROJECT_VERSION = [^;]+' "$PROJECT_FILE" | head -n1 | sed 's/CURRENT_PROJECT_VERSION = //')"
NEXT_BUILD=$((CURRENT_BUILD + 1))

"$SCRIPT_DIR/bump_version.sh" "$CURRENT_VERSION" "$NEXT_BUILD"
