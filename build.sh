#!/bin/sh
set -eu

cd "$(dirname "$0")"

if ! command -v tuist >/dev/null 2>&1; then
    echo "build.sh: tuist is not installed; it generates MobileHarmonica.xcworkspace from Project.swift" >&2
    exit 1
fi

tuist generate --no-open
echo "build.sh: MobileHarmonica.xcworkspace is generated; open it and run the MobileHarmonica scheme"
