# Nitro Rust runtime

This repository is a mechanically extracted subset of
[OffchainLabs/nitro](https://github.com/OffchainLabs/nitro). It packages the Rust crates needed to
execute Stylus programs as normal Cargo Git dependencies without fetching Nitro's unrelated Go,
contract, SDK, and test submodules.

The Rust source is copied unchanged from the revisions recorded in `UPSTREAM_REVISIONS`. Only the
two workspace manifests are reduced to the packages present in this repository.

## Updating

Initialize Nitro's Brotli and Wasmer submodules, check out the intended Nitro revision, then run:

```sh
./scripts/update.sh /path/to/nitro
cargo check -p stylus --features cc_brotli
```

Commit the generated update and pin that commit from consumers with Cargo's `git` and `rev`
fields. All Nitro runtime packages in one consumer must use the same repository revision so their
Wasmer types remain identical.

## Included packages

- `stylus`
- `prover` and `prover-ffi`
- `arbutil`, `brotli`, `caller-env`, and `validation`
- `forward` and `user-host-trait`
- the transitive package closure from Nitro's pinned Wasmer fork

The upstream Nitro and Wasmer licenses are included with the extracted source.
