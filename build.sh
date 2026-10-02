#!/usr/bin/env bash
set -euo pipefail

FLUTTER_VERSION="3.24.3"
FLUTTER_CHANNEL="stable"
FLUTTER_DIR="$HOME/flutter"

echo "=== Installing Flutter $FLUTTER_VERSION ==="

# Fix git ownership issues on Vercel (runs as root)
git config --global --add safe.directory "$FLUTTER_DIR" 2>/dev/null || true

if [ ! -f "$FLUTTER_DIR/bin/flutter" ]; then
  rm -rf "$FLUTTER_DIR"
  curl -fsSL \
    "https://storage.googleapis.com/flutter_infra_release/releases/${FLUTTER_CHANNEL}/linux/flutter_linux_${FLUTTER_VERSION}-${FLUTTER_CHANNEL}.tar.xz" \
    -o /tmp/flutter.tar.xz
  tar xf /tmp/flutter.tar.xz -C "$HOME"
fi

# Mark flutter dir as safe for git
git config --global --add safe.directory "$FLUTTER_DIR" 2>/dev/null || true

export PATH="$FLUTTER_DIR/bin:$PATH"
export FLUTTER_ROOT="$FLUTTER_DIR"
# Suppress root warning
export FLUTTER_ALREADY_CHECKED_FOR_ROOT=true

echo "Flutter at: $(which flutter)"
flutter --version

flutter config --no-analytics
flutter config --enable-web

echo "=== Getting dependencies ==="
flutter pub get

echo "=== Building Flutter web ==="
# No service worker: it served stale JS/Dart after redeploys.
flutter build web --release --web-renderer canvaskit --no-tree-shake-icons --pwa-strategy=none

# Browsers that installed an earlier service worker keep serving its stale cache
# (including a broken icon font). This replacement wipes caches, unregisters, and reloads.
cat > build/web/flutter_service_worker.js <<'EOF'
self.addEventListener('install', () => self.skipWaiting());
self.addEventListener('activate', (event) => {
  event.waitUntil((async () => {
    const keys = await caches.keys();
    await Promise.all(keys.map((k) => caches.delete(k)));
    await self.registration.unregister();
    const windows = await self.clients.matchAll({ type: 'window' });
    windows.forEach((c) => c.navigate(c.url));
  })());
});
EOF

echo "=== Build complete: build/web ==="
