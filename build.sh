#!/bin/sh
set -eu

cd "$(dirname "$0")"

if ! command -v xcodegen >/dev/null 2>&1; then
    echo "build.sh: xcodegen is not installed; it generates MobileHarmonica.xcodeproj from project.yml" >&2
    exit 1
fi

xcodegen generate
echo "build.sh: MobileHarmonica.xcodeproj is generated; open it and run the MobileHarmonica scheme"
