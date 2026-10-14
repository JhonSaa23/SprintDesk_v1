#!/usr/bin/env bash
set -e

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
export PATH="$HOME/flutter_3.24.5/bin:$HOME/.cargo/bin:$PATH"
export VCPKG_ROOT="$HOME/vcpkg"

cd "$DIR/flutter"
rm -f build/macos/Build/Products/Debug/SprintDesk.app/Contents/Frameworks/native_assets.json
flutter run -d macos "$@"
