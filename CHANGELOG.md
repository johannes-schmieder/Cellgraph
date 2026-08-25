# Changelog

## Unreleased

## 0.5.0 - 2026-08-25

First formal semantic-version release and the source release intended for the
initial SSC submission.

### Added

- Added support for string variables in `by()`.
- Added `controls()` for partialling out covariates with `reghdfe`.
- Added `saving()` for retaining the collapsed graph data.
- Added `xorder()` for ordering categorical cells by a selected statistic.
- Added `xlabel()` and `ylabel()` customization.
- Added optional `gtools` and `ftools` collapse backends.
- Added an expanded automated Stata test suite and runnable help examples.
- Documented the development, GitHub Release, tagged-release, and SSC
  distribution channels.
- Added automated checks for release-policy files, package manifests, and
  tag-specific version/date consistency.

### Fixed

- Fixed `lfit` with non-mean statistics for one-by-variable graphs.
- Fixed filtering of observations with missing `by()` values.
- Preserved confidence-interval widths under baseline normalization.

### Changed

- Set the supported minimum version to Stata 18 across all distributed ado
  files and package metadata.
- Clarified that installation from `main` is a development installation.
- Corrected the package manifest so it lists only files distributed by the
  package.
