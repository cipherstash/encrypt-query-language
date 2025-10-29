# Documentation Release Workflow Design

**Date**: 2025-10-29
**Status**: Approved
**Author**: Design session with user

## Overview

This design adds automated documentation generation and publishing to GitHub releases for the EQL project. When an EQL release is published, Doxygen-generated API documentation will be packaged as ZIP and tarball archives and attached to the release.

## Requirements

### Functional Requirements
- Generate API documentation from Doxygen comments on EQL releases
- Validate documentation before generation (coverage + required tags)
- Package documentation as downloadable archives (ZIP and tarball)
- Publish archives to GitHub release assets
- Support local testing via `mise` tasks

### Non-Functional Requirements
- Workflow runs in parallel with SQL build (no blocking)
- Documentation failures don't block SQL release
- Consistent with existing project patterns (mise tasks)
- Fast execution (< 10 minutes)

## Design Decisions

### Trigger: On EQL Release Tags
- Documentation workflow triggered when release published with tag containing 'eql' (e.g., `eql-v1.2.3`)
- Same trigger conditions as existing `build-and-publish` job
- Also supports `pull_request` and `workflow_dispatch` for testing

**Rationale**: Keeps documentation in sync with code releases. Users download docs matching their EQL version.

### Destination: GitHub Release Assets
- Documentation archives attached to GitHub release (not GitHub Pages)
- Matches pattern of SQL file releases
- Simple download experience for users

**Rationale**: Consistent with current release workflow. Users already download SQL files from releases.

### Format: ZIP + Tarball
- Create both `.zip` and `.tar.gz` archives
- Archives contain the generated `html/` directory with all documentation

**Rationale**: Accommodates user preferences (Windows users prefer ZIP, Linux/Unix users prefer tarball).

### Validation: Existing Tasks + Sanity Checks
- **Precheck**: Reuse `mise run docs:validate` (checks coverage + required tags)
- **Sanity check**: Verify `docs/api/html/index.html` exists before packaging

**Rationale**: Leverage existing validation infrastructure from phase-4-docs work.

## Architecture

### Workflow Structure

```
.github/workflows/release-eql.yml
├── build-and-publish (existing job)
│   └── Builds and publishes SQL files
│
└── publish-docs (new job, parallel)
    ├── Install doxygen
    ├── Validate docs (mise run docs:validate)
    ├── Generate docs (mise run docs:generate)
    ├── Package docs (mise run docs:package)
    └── Upload to release
```

**Job Dependencies**: `publish-docs` runs in **parallel** with `build-and-publish` (no `needs:` clause).

**Rationale**:
- Documentation generation is independent of SQL build
- Faster total workflow time
- Docs failures don't block SQL release
- Both jobs can publish concurrently

### Mise Tasks

**Existing tasks** (already implemented in continue-doxygen-sql-comments branch):
- `docs:validate` - Runs coverage check and validates required tags
  - Script: `tasks/check-doc-coverage.sh`
  - Script: `tasks/validate-required-tags.sh`
- `docs:generate` - Runs `doxygen Doxyfile` to create `docs/api/html/`

**New task** (to be implemented):
- `docs:package` - Creates ZIP and tarball archives
  - Script: `tasks/docs-package.sh`
  - Input: `docs/api/html/` directory
  - Output: `release/eql-docs-${VERSION}.zip` and `release/eql-docs-${VERSION}.tar.gz`
  - Version passed as argument from workflow

## Implementation Details

### New Task: `docs:package`

**File**: `tasks/docs-package.sh`

**Responsibilities**:
1. Validate `docs/api/html/` exists and contains files
2. Create `release/` directory if needed
3. Create ZIP archive from `docs/api/html/`
4. Create tarball archive from `docs/api/html/`
5. Report created artifacts

**Script outline**:
```bash
#!/bin/bash
set -e

VERSION=${1:-"dev"}
OUTPUT_DIR="release"

# Validate docs exist
if [ ! -f "docs/api/html/index.html" ]; then
  echo "Error: docs/api/html/ not found. Run 'mise run docs:generate' first"
  exit 1
fi

# Create output directory
mkdir -p "${OUTPUT_DIR}"

# Create archives
cd docs/api
zip -r "../../${OUTPUT_DIR}/eql-docs-${VERSION}.zip" html/
tar czf "../../${OUTPUT_DIR}/eql-docs-${VERSION}.tar.gz" html/

echo "Created:"
echo "  ${OUTPUT_DIR}/eql-docs-${VERSION}.zip"
echo "  ${OUTPUT_DIR}/eql-docs-${VERSION}.tar.gz"
```

**Task definition** (add to `mise.toml`):
```toml
[tasks."docs:package"]
description = "Package documentation for release"
run = """
  ./tasks/docs-package.sh {{arg(name="version", default="dev")}}
"""
```

### GitHub Workflow Job

**Add to `.github/workflows/release-eql.yml`**:

```yaml
publish-docs:
  runs-on: ubuntu-latest
  name: Build and Publish Documentation
  if: ${{ github.event_name != 'release' || contains(github.event.release.tag_name, 'eql') }}
  timeout-minutes: 10

  steps:
    - uses: actions/checkout@v4

    - uses: jdx/mise-action@v2
      with:
        version: 2025.1.6
        install: true
        cache: true

    - name: Install Doxygen
      run: |
        sudo apt-get update
        sudo apt-get install -y doxygen

    - name: Validate documentation
      run: |
        mise run docs:validate

    - name: Generate documentation
      run: |
        mise run docs:generate

    - name: Package documentation
      run: |
        mise run docs:package -- ${{ github.event.release.tag_name }}

    - name: Upload documentation artifacts
      uses: actions/upload-artifact@v4
      with:
        name: eql-docs
        path: |
          release/eql-docs-*.zip
          release/eql-docs-*.tar.gz

    - name: Publish documentation to release
      uses: softprops/action-gh-release@v2
      if: startsWith(github.ref, 'refs/tags/')
      with:
        files: |
          release/eql-docs-*.zip
          release/eql-docs-*.tar.gz
```

## Testing Strategy

### Local Testing
Developers can test the entire workflow locally:
```bash
# Validate documentation
mise run docs:validate

# Generate documentation
mise run docs:generate

# Package for release
mise run docs:package -- eql-v1.2.3

# Verify archives
ls -lh release/eql-docs-*.{zip,tar.gz}
unzip -t release/eql-docs-*.zip
```

### CI Testing
- Pull requests will run all steps except the final publish
- Artifacts uploaded for manual review in GitHub Actions UI
- Only actual release tags trigger publication to release assets

## Deployment Plan

### Files to Create/Modify

**New files**:
1. `tasks/docs-package.sh` - Packaging script
2. `docs/plans/2025-10-29-documentation-release-workflow-design.md` - This document

**Modified files**:
1. `mise.toml` - Add `docs:package` task definition
2. `.github/workflows/release-eql.yml` - Add `publish-docs` job

**Files already merged into continue-doxygen-sql-comments** (ready to merge to main):
1. `Doxyfile` - Doxygen configuration ✅
2. `tasks/doxygen-filter.sh` - SQL comment filter for Doxygen ✅
3. `tasks/check-doc-coverage.sh` - Coverage validation script ✅
4. `tasks/validate-required-tags.sh` - Tag validation script ✅
5. `docs:validate` and `docs:generate` task definitions in `mise.toml` ✅

### Implementation Steps

1. **✅ Merge phase-4-docs work** (COMPLETED)
   - Infrastructure merged into continue-doxygen-sql-comments branch
   - Doxyfile and validation scripts now present
   - `docs:validate` and `docs:generate` tasks added to mise.toml

2. **Create packaging task**
   - Write `tasks/docs-package.sh`
   - Add task definition to `mise.toml`
   - Test locally

3. **Update workflow**
   - Add `publish-docs` job to `release-eql.yml`
   - Test on feature branch via `workflow_dispatch`

4. **Validate on PR**
   - Create PR to verify workflow runs
   - Check artifacts uploaded correctly
   - Verify no errors in validation/generation steps

5. **Release**
   - Merge to main
   - Next EQL release will include documentation archives

## Success Criteria

- [ ] Documentation validates successfully (100% coverage, all required tags)
- [ ] Doxygen generates HTML without errors
- [ ] Both ZIP and tarball archives created
- [ ] Archives attached to GitHub release
- [ ] Workflow completes in < 10 minutes
- [ ] Documentation failures don't block SQL release
- [ ] Developers can test locally with `mise run docs:package`

## Alternative Approaches Considered

### Separate Workflow File
**Approach**: Create `release-docs.yml` instead of adding job to `release-eql.yml`

**Pros**: Clean separation, easier to debug independently
**Cons**: Duplicates setup steps (checkout, mise installation)
**Decision**: Rejected - prefer single release workflow for simplicity

### Sequential Job (docs after SQL build)
**Approach**: Add `needs: build-and-publish` to docs job

**Pros**: Ensures SQL builds successfully first
**Cons**: Slower, docs blocked by SQL failures
**Decision**: Rejected - docs and SQL are independent, parallel is faster

### GitHub Pages Publishing
**Approach**: Publish to GitHub Pages instead of/in addition to release assets

**Pros**: Browsable online docs
**Cons**: Requires gh-pages branch setup, versioning complexity
**Decision**: Rejected for initial implementation - can add later if needed

### Single Archive Format
**Approach**: Provide only ZIP or only tarball

**Pros**: Simpler packaging, less upload time
**Cons**: Doesn't accommodate all user preferences
**Decision**: Rejected - both formats are cheap to provide

## Future Enhancements

- **GitHub Pages**: Publish to `docs.cipherstash.com` for browsable docs
- **Versioned docs**: Maintain docs for multiple versions (e.g., v1.x, v2.x)
- **PDF generation**: Add PDF output from Doxygen for offline reading
- **Link validation**: Add automated link checker to validation step
- **Coverage trends**: Track documentation coverage over time

## References

- Existing workflow: `.github/workflows/release-eql.yml`
- Existing test workflow: `.github/workflows/test-eql.yml`
- Complete docs branch: `continue-doxygen-sql-comments` (includes merged infrastructure)
- Doxygen configuration: `Doxyfile`
- Documentation scripts: `tasks/check-doc-coverage.sh`, `tasks/validate-required-tags.sh`
