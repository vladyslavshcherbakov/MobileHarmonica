#!/bin/sh
set -eu

cd "$(dirname "$0")"

buildTheCore() {
    sh Scripts/buildCore.sh
}

buildThePage() {
    if [ ! -f core/harmonica.wasm ]; then
        echo "build.sh: core/harmonica.wasm is missing; ./build.sh core builds it" >&2
        exit 1
    fi

    node Scripts/prepareSamples.mjs
    rm -rf dist
    npx tsc
    node --test "dist/tests/**/*.test.js"
}

stampThePage() {
    node Scripts/stampTheBuild.mjs "$1"
}

part="${1:-all}"
case "$part" in
    core)
        buildTheCore
        ;;
    page)
        buildThePage
        if [ "$#" -gt 1 ]; then stampThePage "$2"; fi
        ;;
    all)
        buildTheCore
        buildThePage
        ;;
    *)
        echo "build.sh: $part is not a part; build core, page [version], or all" >&2
        exit 1
        ;;
esac
