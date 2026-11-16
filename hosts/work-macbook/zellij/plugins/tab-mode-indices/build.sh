#!/bin/sh
set -eu
cd "$(dirname "$0")"
cargo build --locked --release --target wasm32-wasip1
cp target/wasm32-wasip1/release/tab-mode-indices.wasm ../tab-mode-indices.wasm
