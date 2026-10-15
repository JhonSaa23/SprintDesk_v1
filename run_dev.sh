#!/usr/bin/env bash
set -e

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
export PATH="$HOME/flutter_3.24.5/bin:$HOME/.cargo/bin:$PATH"
export VCPKG_ROOT="$HOME/vcpkg"

cd "$DIR/flutter"
rm -rf build/native_assets build/macos/Build/Products/Debug/SprintDesk.app/Contents/Frameworks/native_assets.json "$HOME"/Library/Developer/Xcode/DerivedData/Runner*/Build/Products/Debug/SprintDesk.app/Contents/Frameworks/native_assets.json

# Ensure fresh AppIcon in DerivedData and clear dock icon cache
for dd in "$HOME"/Library/Developer/Xcode/DerivedData/Runner*/Build/Products/Debug/SprintDesk.app; do
  if [ -d "$dd" ]; then
    cp -f macos/Runner/AppIcon.icns "$dd/Contents/Resources/AppIcon.icns" 2>/dev/null || true
    touch "$dd"
  fi
done

flutter run -d macos "$@"
