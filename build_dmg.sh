#!/usr/bin/env bash
set -e

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
export PATH="$HOME/flutter_3.24.5/bin:$HOME/.cargo/bin:$PATH"
export VCPKG_ROOT="$HOME/vcpkg"

echo "==============================================="
echo "  🚀 Generando instalador .DMG de SprintDesk"
echo "==============================================="

# 1. Detectar arquitectura (arm64 o x86_64)
ARCH=$(uname -m)
VERSION="1.5.0"
DMG_NAME="SprintDesk-${VERSION}-${ARCH}.dmg"

echo "==> Arquitectura detectada: $ARCH"

# 2. Compilar dylib de Rust en Release
echo "==> 1/4 Compilando Rust backend (release)..."
cd "$DIR"
MACOSX_DEPLOYMENT_TARGET=10.14 cargo build --locked --features flutter,hwcodec --release
cp -f target/release/liblibrustdesk.dylib target/release/librustdesk.dylib 2>/dev/null || true

# 3. Compilar Flutter en Release
echo "==> 2/4 Compilando Flutter macOS (release)..."
cd "$DIR/flutter"
FLUTTER_XCODE_ARCHS="$ARCH" FLUTTER_XCODE_ONLY_ACTIVE_ARCH=YES flutter build macos --release

APP_PATH="$DIR/flutter/build/macos/Build/Products/Release/SprintDesk.app"

if [ ! -d "$APP_PATH" ]; then
  # Fallback si el nombre generado es RustDesk.app
  if [ -d "$DIR/flutter/build/macos/Build/Products/Release/RustDesk.app" ]; then
    APP_PATH="$DIR/flutter/build/macos/Build/Products/Release/RustDesk.app"
  else
    echo "❌ Error: No se encontró el .app en $DIR/flutter/build/macos/Build/Products/Release/"
    exit 1
  fi
fi

# Copiar servicio binario dentro del .app si existe
if [ -f "$DIR/target/release/service" ]; then
  cp -f "$DIR/target/release/service" "$APP_PATH/Contents/MacOS/" 2>/dev/null || true
fi

# 4. Crear imagen DMG con acceso directo a Aplicaciones
echo "==> 3/4 Empaquetando en DMG..."
STAGING_DIR="$DIR/flutter/build/macos/dmg_staging"
rm -rf "$STAGING_DIR"
mkdir -p "$STAGING_DIR"

cp -R "$APP_PATH" "$STAGING_DIR/SprintDesk.app"
ln -s /Applications "$STAGING_DIR/Aplicaciones"

cd "$DIR"
rm -f "$DMG_NAME"

hdiutil create \
  -volname "SprintDesk" \
  -srcfolder "$STAGING_DIR" \
  -ov \
  -format UDZO \
  "$DMG_NAME"

rm -rf "$STAGING_DIR"

echo "==============================================="
echo "  ✅ ¡DMG generado exitosamente!"
echo "  📍 Ubicación: $DIR/$DMG_NAME"
echo "==============================================="
