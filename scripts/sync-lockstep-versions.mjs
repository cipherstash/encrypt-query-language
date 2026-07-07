// Propagate the changesets-computed npm version to the rest of the EQL release.
//
// `@cipherstash/eql`'s package.json version (owned by `changeset version`) is the
// single source of truth for the EQL release identity V. SQL, the Rust crate,
// and the npm package all ship at V (they're generated from one catalog at one
// commit). This runs as the second half of the root `version` script — right
// after `changeset version` — so the resulting "Version Packages" commit is a
// complete, consistent lockstep bump (which release-plz then publishes verbatim
// from the committed tree).
//
// It:
//   1. reads V from packages/eql/package.json,
//   2. sets crates/eql-bindings/Cargo.toml [package] version = V,
//   3. runs `mise run release:prepare_bindings_assets --version V`, which builds
//      the exact-version SQL and writes it (+ release manifests) into both the
//      crate and the npm package.

import { execFileSync } from 'node:child_process'
import { readFileSync, writeFileSync } from 'node:fs'
import { dirname, join } from 'node:path'
import { fileURLToPath } from 'node:url'

const repoRoot = join(dirname(fileURLToPath(import.meta.url)), '..')

const pkgPath = join(repoRoot, 'packages/eql/package.json')
const version = JSON.parse(readFileSync(pkgPath, 'utf8')).version
if (typeof version !== 'string' || version.length === 0) {
  throw new Error(`could not read a version from ${pkgPath}`)
}

// Set the crate's [package] version. Only the package version sits at column 0
// as `version = "..."`; dependency versions are inline (`{ version = "1" }`).
const cargoPath = join(repoRoot, 'crates/eql-bindings/Cargo.toml')
const cargo = readFileSync(cargoPath, 'utf8')
const cargoNext = cargo.replace(/^version = "[^"]*"$/m, `version = "${version}"`)
if (cargoNext === cargo) {
  throw new Error(`did not find a [package] version line to update in ${cargoPath}`)
}
writeFileSync(cargoPath, cargoNext)

// Build the exact-version SQL and copy it (+ manifests) into both packages.
execFileSync('mise', ['run', 'release:prepare_bindings_assets', '--version', version], {
  cwd: repoRoot,
  stdio: 'inherit',
})

console.log(`synced EQL lockstep version ${version} to Cargo.toml + bundled SQL assets`)
