#!/usr/bin/env node
import { readFileSync } from 'node:fs'
import { dirname, resolve } from 'node:path'
import { spawnSync } from 'node:child_process'
import { fileURLToPath } from 'node:url'

const packageRoot = resolve(dirname(fileURLToPath(import.meta.url)), '..')
const pkg = JSON.parse(readFileSync(resolve(packageRoot, 'package.json'), 'utf8'))
const prerelease = pkg.version.match(/-(alpha|beta|rc)\./)
const tag = prerelease ? prerelease[1] : 'latest'

console.log(`publishing ${pkg.name}@${pkg.version} with npm dist-tag '${tag}'`)

// The bundled-SQL freshness guard lives in prepublishOnly
// (scripts/verify-release-assets.mjs), which `npm publish` runs for every
// publish path — including `changeset publish` on the production side.
const result = spawnSync(
  'npm',
  ['publish', '--access', 'public', '--provenance', '--tag', tag, ...process.argv.slice(2)],
  { cwd: packageRoot, stdio: 'inherit' },
)

process.exit(result.status ?? 1)
