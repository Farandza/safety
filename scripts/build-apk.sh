#!/usr/bin/env bash
set -euo pipefail
if [ -f /workspace/work/flutter-env.sh ]; then source /workspace/work/flutter-env.sh; fi
cd "$(dirname "$0")/.."
flutter build apk --release "$@"
cp build/app/outputs/flutter-apk/app-release.apk safety.apk
