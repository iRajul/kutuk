#!/bin/sh

set -eu

SCRIPT_DIR="$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)"
REPO_ROOT="$(CDPATH= cd -- "$SCRIPT_DIR/.." && pwd)"
cd "$REPO_ROOT"
PROJECT_FILE="kutuk.xcodeproj/project.pbxproj"
PLIST_FILES="kutuk/Info.plist kutukTests/Info.plist kutukUITests/Info.plist"

if [ "${1:-}" = "" ]; then
  echo "Usage: $0 <marketing-version> [build-number]" >&2
  exit 1
fi

NEW_VERSION="$1"
OVERRIDE_BUILD="${2:-}"

case "$NEW_VERSION" in
  *[!0-9.]* | .* | *..* | *.)
    echo "Invalid marketing version: $NEW_VERSION" >&2
    exit 1
    ;;
esac

CURRENT_VERSION="$(rg -o 'MARKETING_VERSION = [^;]+' "$PROJECT_FILE" | head -n1 | sed 's/MARKETING_VERSION = //')"
CURRENT_BUILD="$(rg -o 'CURRENT_PROJECT_VERSION = [^;]+' "$PROJECT_FILE" | head -n1 | sed 's/CURRENT_PROJECT_VERSION = //')"

case "$CURRENT_BUILD" in
  '' | *[!0-9]*)
    echo "Current build number must be an integer, found: $CURRENT_BUILD" >&2
    exit 1
    ;;
esac

if [ -n "$OVERRIDE_BUILD" ]; then
  NEXT_BUILD="$OVERRIDE_BUILD"
else
  if [ "$NEW_VERSION" = "$CURRENT_VERSION" ]; then
    NEXT_BUILD="$CURRENT_BUILD"
  else
    NEXT_BUILD=$((CURRENT_BUILD + 1))
  fi
fi

case "$NEXT_BUILD" in
  '' | *[!0-9]*)
    echo "Build number must be an integer, found: $NEXT_BUILD" >&2
    exit 1
    ;;
esac

if [ -z "$CURRENT_VERSION" ] || [ -z "$CURRENT_BUILD" ]; then
  echo "Could not read version settings from $PROJECT_FILE" >&2
  exit 1
fi

export CURRENT_VERSION CURRENT_BUILD NEW_VERSION NEXT_BUILD

perl -0pi -e 's/MARKETING_VERSION = \Q$ENV{CURRENT_VERSION}\E;/MARKETING_VERSION = $ENV{NEW_VERSION};/g; s/CURRENT_PROJECT_VERSION = \Q$ENV{CURRENT_BUILD}\E;/CURRENT_PROJECT_VERSION = $ENV{NEXT_BUILD};/g' "$PROJECT_FILE"

for plist in $PLIST_FILES; do
  /usr/libexec/PlistBuddy -c "Set :CFBundleShortVersionString $NEW_VERSION" "$plist"
  /usr/libexec/PlistBuddy -c "Set :CFBundleVersion $NEXT_BUILD" "$plist"
done

echo "Updated marketing version: $CURRENT_VERSION -> $NEW_VERSION"
echo "Updated build number: $CURRENT_BUILD -> $NEXT_BUILD"
