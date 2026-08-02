#!/usr/bin/env bash
set -euo pipefail

root=$(cd "$(dirname "$0")/.." && pwd)
nitro=${1:?usage: scripts/update.sh /path/to/nitro [nitro-ref]}
ref=${2:-HEAD}

nitro=$(cd "$nitro" && pwd)
revision=$(git -C "$nitro" rev-parse "$ref^{commit}")
head=$(git -C "$nitro" rev-parse HEAD)
if [[ "$revision" != "$head" ]]; then
    echo "Nitro checkout must be at $revision; current HEAD is $head" >&2
    exit 1
fi

git -C "$nitro" submodule update --init brotli crates/tools/wasmer
brotli_revision=$(git -C "$nitro/brotli" rev-parse HEAD)
wasmer_revision=$(git -C "$nitro/crates/tools/wasmer" rev-parse HEAD)

expected_brotli=$(git -C "$nitro" ls-tree "$revision" brotli | awk '{print $3}')
expected_wasmer=$(git -C "$nitro" ls-tree "$revision" crates/tools/wasmer | awk '{print $3}')
if [[ "$brotli_revision" != "$expected_brotli" || "$wasmer_revision" != "$expected_wasmer" ]]; then
    echo "Nitro submodules do not match $revision" >&2
    exit 1
fi

tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT
mkdir -p "$tmp/brotli" "$tmp/crates/tools/wasmer"

nitro_paths=(
    Cargo.toml Cargo.lock LICENSE.md rust-toolchain.toml
    crates/arbutil crates/brotli crates/caller-env crates/validation
    crates/prover crates/prover-ffi crates/stylus
    crates/wasm-libraries/forward crates/wasm-libraries/user-host-trait
)
for item in "${nitro_paths[@]}"; do
    git -C "$nitro" archive "$revision" "$item" | tar -x -C "$tmp"
done
git -C "$nitro/brotli" archive "$brotli_revision" | tar -x -C "$tmp/brotli"

wasmer_paths=(
    Cargo.toml Cargo.lock LICENSE README.md rust-toolchain.toml
    lib/api lib/compiler lib/compiler-cranelift lib/compiler-llvm
    lib/compiler-singlepass lib/derive lib/types lib/vm
)
for item in "${wasmer_paths[@]}"; do
    git -C "$nitro/crates/tools/wasmer" archive "$wasmer_revision" "$item" |
        tar -x -C "$tmp/crates/tools/wasmer"
done

python3 "$root/scripts/reduce_workspaces.py" "$tmp"
cargo generate-lockfile --manifest-path "$tmp/Cargo.toml"

rm -rf \
    "$root/brotli" \
    "$root/crates/arbutil" \
    "$root/crates/brotli" \
    "$root/crates/caller-env" \
    "$root/crates/prover" \
    "$root/crates/prover-ffi" \
    "$root/crates/stylus" \
    "$root/crates/validation" \
    "$root/crates/wasm-libraries" \
    "$root/crates/tools/wasmer"

cp -R "$tmp/brotli" "$root/brotli"
cp -R "$tmp/crates/." "$root/crates"
cp "$tmp/Cargo.toml" "$tmp/Cargo.lock" "$tmp/LICENSE.md" "$tmp/rust-toolchain.toml" "$root/"

cat > "$root/UPSTREAM_REVISIONS" <<EOF
nitro $revision
brotli $brotli_revision
wasmer $wasmer_revision
EOF

echo "Extracted Nitro $revision"
