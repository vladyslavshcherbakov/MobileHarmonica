#!/bin/sh
set -eu

cd "$(dirname "$0")/.."

sdk="${SWIFT_WASM_SDK:-swift-6.4.0-RELEASE_wasm}"

if ! swift build --package-path Instrument --product HarmonicaWasm --swift-sdk "$sdk" -c release \
    -Xswiftc -Xclang-linker -Xswiftc -mexec-model=reactor -Xlinker -s; then
    echo "buildCore.sh: swift build failed; is the WebAssembly SDK $sdk installed?" >&2
    exit 1
fi

mkdir -p core
cp Instrument/.build/release/HarmonicaWasm.wasm core/harmonica.wasm
echo "buildCore.sh: core/harmonica.wasm is ready"
