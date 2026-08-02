#!/usr/bin/env python3
import pathlib
import re
import sys


root = pathlib.Path(sys.argv[1])

nitro_manifest = root / "Cargo.toml"
nitro = nitro_manifest.read_text()
nitro_workspace = '''[workspace]
members = [
    "crates/arbutil",
    "crates/brotli",
    "crates/caller-env",
    "crates/validation",
    "crates/prover",
    "crates/prover-ffi",
    "crates/stylus",
    "crates/wasm-libraries/forward",
    "crates/wasm-libraries/user-host-trait",
]
default-members = ["crates/stylus"]
exclude = ["crates/stylus/tests", "crates/tools"]
resolver = "2"

'''
nitro = re.sub(r"\A\[workspace\].*?(?=\[workspace\.package\])", nitro_workspace, nitro, flags=re.S)
nitro_manifest.write_text(nitro)

wasmer_manifest = root / "crates/tools/wasmer/Cargo.toml"
wasmer = wasmer_manifest.read_text()
wasmer_workspace = '''[workspace]
members = [
    "lib/api",
    "lib/api/macro-wasmer-universal-test",
    "lib/compiler",
    "lib/compiler-cranelift",
    "lib/compiler-llvm",
    "lib/compiler-singlepass",
    "lib/derive",
    "lib/types",
    "lib/vm",
]
resolver = "2"

'''
workspace_settings = re.search(
    r"\[workspace\.package\].*?(?=\n\[build-dependencies\])", wasmer, flags=re.S
)
if workspace_settings is None:
    raise RuntimeError("could not locate Wasmer workspace settings")
wasmer = wasmer_workspace + workspace_settings.group(0).rstrip() + "\n"
wasmer_manifest.write_text(wasmer)
