#!/usr/bin/env bash

set -euo pipefail

print_usage() {
  cat <<'USAGE'
Scaffold this base project into a destination directory.

Usage:
  tools/scaffold.sh /absolute/path/to/destination [--force] [--name APP_NAME] [--display-name DISPLAY] [--android-id ANDROID_PKG] [--ios-id IOS_BUNDLE_ID]

Options:
  --force                    Overwrite existing files in destination
  --name APP_NAME            Replace occurrences of base project name with APP_NAME (pubspec, text)
  --display-name DISPLAY     Set human-friendly app name (Android label, iOS display/name)
  --android-id ANDROID_PKG   Set Android applicationId and namespace (e.g. com.example.app)
  --ios-id IOS_BUNDLE_ID     Set iOS bundle identifier (e.g. com.example.app)

Notes:
  - Run from the repository root.
  - Destination must be an absolute path.
USAGE
}

require_cmd() {
  if ! command -v "$1" >/dev/null 2>&1; then
    echo "Error: required command '$1' not found" >&2
    exit 1
  fi
}

is_absolute_path() {
  case "$1" in
    /*) return 0 ;;
    *) return 1 ;;
  esac
}

DEST=""
FORCE=0
APP_NAME=""
DISPLAY_NAME=""
ANDROID_ID=""
IOS_ID=""

while (( "$#" )); do
  case "${1:-}" in
    -h|--help)
      print_usage; exit 0 ;;
    --force)
      FORCE=1; shift ;;
    --name)
      APP_NAME="${2:-}"; shift 2 || { echo "--name requires a value" >&2; exit 1; } ;;
    --display-name)
      DISPLAY_NAME="${2:-}"; shift 2 || { echo "--display-name requires a value" >&2; exit 1; } ;;
    --android-id)
      ANDROID_ID="${2:-}"; shift 2 || { echo "--android-id requires a value" >&2; exit 1; } ;;
    --ios-id)
      IOS_ID="${2:-}"; shift 2 || { echo "--ios-id requires a value" >&2; exit 1; } ;;
    --)
      shift; break ;;
    -*)
      echo "Unknown option: $1" >&2; print_usage; exit 2 ;;
    *)
      if [[ -z "$DEST" ]]; then DEST="$1"; else echo "Unexpected argument: $1" >&2; exit 2; fi; shift ;;
  esac
done

if [[ -z "$DEST" ]]; then
  echo "Error: destination path is required" >&2
  print_usage
  exit 2
fi

if ! is_absolute_path "$DEST"; then
  echo "Error: destination must be an absolute path: $DEST" >&2
  exit 2
fi

# Ensure required tools
require_cmd rsync
require_cmd sed

REPO_ROOT="$(pwd)"
if [[ ! -f "$REPO_ROOT/pubspec.yaml" ]]; then
  echo "Error: run this script from the repository root (pubspec.yaml not found)." >&2
  exit 2
fi

mkdir -p "$DEST"

RSYNC_FLAGS=(
  -a
  --delete-excluded
  --prune-empty-dirs
)

if [[ "$FORCE" -eq 1 ]]; then
  RSYNC_FLAGS+=(--ignore-errors)
fi

# Exclude patterns
EXCLUDES=(
  --exclude build/
  --exclude .git/
  --exclude .idea/
  --exclude .vscode/
  --exclude .dart_tool/
  --exclude .flutter-plugins
  --exclude .flutter-plugins-dependencies
  --exclude .packages
  --exclude .DS_Store
  --exclude '**/.DS_Store'
  --exclude ios/Pods/
  --exclude ios/Runner.xcworkspace/xcshareddata/WorkspaceSettings.xcsettings
  --exclude ios/Runner.xcodeproj/project.xcworkspace/
  --exclude android/.gradle/
  --exclude android/build/
  --exclude windows/flutter/ephemeral/
  --exclude '**/*.iml'
  --exclude pubspec.lock
)

echo "Copying project to $DEST ..."
rsync "${RSYNC_FLAGS[@]}" "${EXCLUDES[@]}" ./ "$DEST/"

if [[ -n "$APP_NAME" ]]; then
  echo "Renaming project to $APP_NAME ..."
  # Replace app name in pubspec.yaml name field and readable occurrences of base_project
  # Using BSD-compatible sed (macOS); also works with GNU sed
  sed -i '' -E "s/^name:\s*base_project\b/name: ${APP_NAME}/" "$DEST/pubspec.yaml" 2>/dev/null || true
  # Generic textual replacement in a few key files
  FILES_TO_UPDATE=(
    "$DEST/pubspec.yaml"
    "$DEST/ios/Runner/Info.plist"
    "$DEST/android/app/src/main/AndroidManifest.xml"
    "$DEST/README.md"
  )
  for f in "${FILES_TO_UPDATE[@]}"; do
    if [[ -f "$f" ]]; then
      sed -i '' -e "s/base_project/${APP_NAME}/g" "$f" 2>/dev/null || true
    fi
  done
fi

# Apply Android identifiers and display name
if [[ -n "$ANDROID_ID" ]]; then
  echo "Setting Android applicationId and namespace to $ANDROID_ID ..."
  GRADLE_FILE="$DEST/android/app/build.gradle"
  if [[ -f "$GRADLE_FILE" ]]; then
    # applicationId
    sed -i '' -E "s/^[[:space:]]*applicationId[[:space:]]*=.*/        applicationId = \"${ANDROID_ID}\"/" "$GRADLE_FILE" 2>/dev/null || true
    # namespace at top-level android { namespace = "..." }
    sed -i '' -E "s/^[[:space:]]*namespace[[:space:]]*=.*/    namespace = \"${ANDROID_ID}\"/" "$GRADLE_FILE" 2>/dev/null || true
  fi

  # Update Kotlin package and directory if matches default
  MAIN_KT_DIR="$DEST/android/app/src/main/kotlin"
  if [[ -d "$MAIN_KT_DIR" ]]; then
    # expected current: base/project/base_project
    OLD_PKG_DIR="$MAIN_KT_DIR/base/project/base_project"
    if [[ -d "$OLD_PKG_DIR" ]]; then
      NEW_PKG_PATH="${ANDROID_ID//./\/}"
      NEW_PKG_DIR="$MAIN_KT_DIR/$NEW_PKG_PATH"
      mkdir -p "$NEW_PKG_DIR"
      # move files
      find "$OLD_PKG_DIR" -type f -name '*.kt' -maxdepth 1 -print0 | xargs -0 -I{} bash -c 'f="$1"; base="$(basename "$f")"; mv "$f" "$2/$base"' _ {} "$NEW_PKG_DIR"
      # clean old dirs if empty
      rmdir "$DEST/android/app/src/main/kotlin/base/project/base_project" 2>/dev/null || true
      rmdir "$DEST/android/app/src/main/kotlin/base/project" 2>/dev/null || true
      rmdir "$DEST/android/app/src/main/kotlin/base" 2>/dev/null || true
      # update package declaration in moved files
      find "$NEW_PKG_DIR" -type f -name '*.kt' -exec sed -i '' -e "s/^package .*/package ${ANDROID_ID}/" {} +
    fi
  fi

  # Update AndroidManifest activity reference if using shorthand .MainActivity
  MANIFEST_FILE="$DEST/android/app/src/main/AndroidManifest.xml"
  if [[ -f "$MANIFEST_FILE" ]]; then
    # Ensure activity uses full qualified name if needed
    sed -i '' -e "s/android:name=\"\\.MainActivity\"/android:name=\"${ANDROID_ID}.MainActivity\"/" "$MANIFEST_FILE" 2>/dev/null || true
  fi
fi

if [[ -n "$DISPLAY_NAME" ]]; then
  echo "Setting display names to $DISPLAY_NAME ..."
  # Android label
  MANIFEST_FILE="$DEST/android/app/src/main/AndroidManifest.xml"
  if [[ -f "$MANIFEST_FILE" ]]; then
    sed -i '' -E "s/(android:label=\").*(\")/\1${DISPLAY_NAME}\2/" "$MANIFEST_FILE" 2>/dev/null || true
  fi
  # iOS display name and bundle name
  IOS_PLIST="$DEST/ios/Runner/Info.plist"
  if [[ -f "$IOS_PLIST" ]]; then
    # CFBundleDisplayName
    /usr/libexec/PlistBuddy -c "Set :CFBundleDisplayName ${DISPLAY_NAME}" "$IOS_PLIST" 2>/dev/null || \
    /usr/libexec/PlistBuddy -c "Add :CFBundleDisplayName string ${DISPLAY_NAME}" "$IOS_PLIST" 2>/dev/null || true
    # CFBundleName
    /usr/libexec/PlistBuddy -c "Set :CFBundleName ${DISPLAY_NAME}" "$IOS_PLIST" 2>/dev/null || \
    /usr/libexec/PlistBuddy -c "Add :CFBundleName string ${DISPLAY_NAME}" "$IOS_PLIST" 2>/dev/null || true
  fi
fi

# Apply iOS bundle identifier
if [[ -n "$IOS_ID" ]]; then
  echo "Setting iOS bundle identifier to $IOS_ID ..."
  PBXPROJ="$DEST/ios/Runner.xcodeproj/project.pbxproj"
  if [[ -f "$PBXPROJ" ]]; then
    sed -i '' -E "s/(PRODUCT_BUNDLE_IDENTIFIER = )[^;]+;/\1${IOS_ID};/g" "$PBXPROJ" 2>/dev/null || true
  fi
fi

echo "Done. Project scaffolded at: $DEST"


