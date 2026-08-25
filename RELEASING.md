# Releasing Cellgraph

This file is the authoritative process for developing, versioning, releasing,
and distributing `cellgraph`. It is a process guide, not a chronological
release log; release history belongs in [CHANGELOG.md](CHANGELOG.md) and in
GitHub Releases.

## Distribution model

| Channel | Meaning |
| --- | --- |
| `main` | Active development. It may contain work for the next version. |
| `vX.Y.Z-rcN` | Immutable release-candidate snapshot for testing. GitHub prerelease only; never SSC. |
| `vX.Y.Z` | Immutable exact source snapshot of final release `X.Y.Z`. |
| GitHub Release | User-facing release attached to one of the immutable tags. |
| SSC | Current supported stable Stata package, copied from a final release commit. |

`main` is not expected to remain identical to the SSC release. After a stable
release, development can continue immediately on `main`.

The legacy `Pre-release` tag predates this policy. Preserve it as historical
state; do not move or repurpose it. All future release tags use the conventions
below.

## Version numbers and immutable tags

Use semantic-style versions:

- patch (`v0.1.1`) for backward-compatible fixes;
- minor (`v0.2.0`) for backward-compatible features;
- major (`v1.0.0`) for incompatible changes or a deliberate stability
  milestone.

Release candidates use `vX.Y.Z-rc1`, `vX.Y.Z-rc2`, and so on. A candidate does
not become final automatically, even if no code changes follow it. Creating
`vX.Y.Z` is a separate release decision.

Published tags are immutable. Never force-update, move, delete and recreate,
or otherwise rewrite a published final tag. Correct a released defect on
`main` and issue a new patch release.

## Metadata that must agree

Before tagging a release, synchronize:

1. the intended `vX.Y.Z` tag and GitHub Release;
2. the header near the top of `cellgraph.ado`, in the form
   `*! cellgraph X.Y.Z DDmonYYYY`;
3. `d Distribution-Date: YYYYMMDD` in `cellgraph.pkg`;
4. the dated `## X.Y.Z - YYYY-MM-DD` section in `CHANGELOG.md`;
5. any explicit version or date in help or other package metadata;
6. the files listed by `f` entries in `cellgraph.pkg`.

Do not add a standalone `VERSION` file. The release check compares the
existing authoritative metadata directly.

## Prepare and validate a release

1. Work on `main` and ensure the intended release changes are committed.
2. Choose the version and release date.
3. Move completed changelog entries from `Unreleased` into a dated version
   section, leaving a fresh `Unreleased` section at the top.
4. Update the ado header, package distribution date, help, README, and package
   manifest together.
5. Run the complete Stata release test gate. It executes the full suite with
   variable abbreviations both enabled and disabled, installs the package into
   an isolated ado directory, and runs every embedded help example:

   ```bash
   python3 scripts/run_stata_release_tests.py \
       --install-dependencies --require-dependencies
   ```

   The runner uses an isolated ado directory and parses the Stata test
   summaries rather than trusting the batch process exit status. Use
   `--stata /path/to/stata-mp` to select a specific supported Stata
   installation.

6. Run the release check using the intended tag, before creating it:

   ```bash
   python3 scripts/check_release_metadata.py --tag vX.Y.Z
   ```

7. Review `git diff`, confirm that only intended source and distribution files
   are included, and commit the release preparation on `main`.

For an RC, prepare the metadata for the target final version and validate with
the RC tag, for example:

```bash
python3 scripts/check_release_metadata.py --tag v0.2.0-rc1
```

## Create and test a release candidate

Tag the exact prepared commit and push the tag:

```bash
git tag -a vX.Y.Z-rc1 -m "cellgraph X.Y.Z release candidate 1"
git push origin vX.Y.Z-rc1
```

Create a GitHub Release for that tag, mark it as a prerelease, and use concise
notes derived from the changelog. Install and test from the tag URL rather
than from `main`. Never submit an RC to SSC.

If testing finds a problem, fix it on `main`, update metadata or documentation
as needed, rerun the full tests, and create `-rc2` from the new commit. Do not
move `-rc1`.

## Create the final GitHub release

After explicitly selecting the tested final commit:

```bash
python3 scripts/check_release_metadata.py --tag vX.Y.Z
git tag -a vX.Y.Z -m "cellgraph X.Y.Z"
git push origin vX.Y.Z
```

Verify the tag target with `git show vX.Y.Z`, then create a normal GitHub
Release attached to that tag. Use concise user-facing notes derived from the
matching changelog section. Mark a final release as latest when it is the
supported stable version.

If compiled Stata plugins are added later, build platform-specific binaries
from the tagged commit in CI and attach only those tagged-build artifacts to
the GitHub Release.

## Build and submit the SSC package

SSC is not currently an installation channel for this repository. For the
first and every later SSC submission:

1. Start from the final tag, never from the current tip of `main`.
2. Extract or check out the tag into a clean directory, for example:

   ```bash
   release_dir="$(mktemp -d)"
   git archive vX.Y.Z | tar -x -C "$release_dir"
   cd "$release_dir"
   python3 scripts/check_release_metadata.py --tag vX.Y.Z
   ```

3. Run the metadata and Stata release gates in the clean tagged tree, including
   the suite with `set varabbrev off` and all declared dependencies installed.
4. Stage `cellgraph.ado`, `cellgraph.sthlp`, and `cellgraph_run.ado` from the
   final tag in a zip archive. Retain checksums of those exact files.
5. Email that archive to the SSC maintainer with the proposed package name,
   title, functional description, minimum Stata version, and the `reghdfe`,
   `gtools`, and `ftools` dependency relationships clearly identified.
6. Do not include `cellgraph.pkg` in the SSC submission. That file supports
   GitHub `net install`; SSC generates its own package file from the archive
   metadata.
7. Retain the final tag and GitHub Release as the source provenance for every
   submitted file.
8. After SSC acceptance, update `main` documentation so `ssc install
   cellgraph` becomes the recommended stable installation command.

To verify an SSC-bound file independently, compare it with the tag, for
example:

```bash
git show vX.Y.Z:cellgraph.ado | cmp - "$release_dir/cellgraph.ado"
```

Repeat for each of the three SSC-bound source files, or retain checksums of the
clean tagged staging directory with the submission record.

If SSC review reveals a source defect, fix it in Git. Do not silently modify a
published tag or submit files that cannot be traced to it. If a final release
must change, create an appropriate patch release and submit that new final
release to SSC.
