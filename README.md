# Cellgraph

Flexible Stata command to create descriptive figures by collapsing data to
cells. It supports one or two grouping variables, multiple outcomes and
statistics, confidence intervals, linear fits, category ordering, saved
collapsed data, and optional covariate adjustment.

## Requirements

- Stata 18 or newer.
- `reghdfe` is required only for `controls()`.
- `gtools` or `ftools` is required only when the corresponding optional
  performance backend is requested.

## Installation channels

### Stable version (SSC)

`cellgraph` is not currently published on SSC. After its first SSC
publication, the normal installation for ordinary users will be:

```stata
ssc install cellgraph
```

SSC will contain the current supported stable release, corresponding to an
immutable final GitHub release.

### Development version (`main`)

Install the current development tree directly from GitHub with:

```stata
net install cellgraph, replace ///
    from("https://raw.githubusercontent.com/johannes-schmieder/cellgraph/main/")
```

The `main` branch may contain work intended for the next release and is not
necessarily identical to the version on SSC. The alternative command
`github install johannes-schmieder/cellgraph` also follows the repository's
default branch and should therefore be treated as a development install.

### Exact tagged release

To install an immutable final release, replace `vX.Y.Z` with an existing final
release tag:

```stata
net install cellgraph, replace ///
    from("https://raw.githubusercontent.com/johannes-schmieder/cellgraph/vX.Y.Z/")
```

Release candidates such as `v0.5.0-rc1` are for testing only and are never
submitted to SSC.

See [RELEASING.md](RELEASING.md) for the authoritative release process and
[CHANGELOG.md](CHANGELOG.md) for user-facing changes.
