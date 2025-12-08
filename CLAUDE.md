# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

`cellgraph` is a Stata package for creating descriptive graphs by collapsing data to cell level. It provides a flexible interface similar to `tabstat` but produces graphs instead of tables. Data is collapsed by one or two categorical "by" variables, computing cell statistics (mean, percentiles, etc.) which are then plotted.

## Testing

Run the test file in Stata:
```stata
do test_cellgraph.do
```

For development, source the ado file directly before testing:
```stata
do cellgraph.ado
```

Run individual examples from the help file:
```stata
cellgraph_run ex1 using cellgraph.sthlp, preserve
```

## Architecture

### Main Command Flow (cellgraph.ado)
1. Parse syntax and validate inputs (1-2 by-variables, multiple outcome variables allowed)
2. Preserve data and filter to relevant sample
3. Apply binning if requested (`bin()` or `binscatter()`)
4. Partial out covariates if `controls()` specified (requires `reghdfe`)
5. Collapse data to cell level computing requested statistics
6. Build confidence intervals for means
7. Apply baseline normalization if requested
8. Dynamically construct `twoway` graph command with appropriate elements
9. Render graph and restore data

### Helper Programs (in cellgraph.ado)
- `__statlabel` - Converts stat codes (p10, p50, sd, etc.) to readable labels
- `__localfmt` / `__SignificantDigits` - Smart numeric formatting for coefficient display
- `__locallist` - Parses semicolon-separated color/option lists into Stata macros

### File Purposes
- `cellgraph.ado` - Main command implementation
- `cellgraph_run.ado` - Extracts and runs examples embedded in the help file
- `cellgraph.sthlp` - SMCL help file with embedded runnable examples
- `cellgraph.pkg` / `stata.toc` - Package distribution metadata

## Key Implementation Details

- Colors are semicolon-separated (e.g., `colors(dknavy; cranberry)` or `colors(255 0 0; 0 255 0)`)
- Confidence intervals only display for `stat(mean)` with one by-variable or outcome
- The `gradient` option generates an RGB color ramp for the second by-variable
- Uses Stata's `marksample` for sample selection; excludes missing by-variables
- Graph commands are built dynamically as locals and executed via `twoway`

## Optional Dependencies

- `reghdfe` - Required only when using `controls()` option
- `gtools` / `ftools` - Optional performance optimization for collapse step

## Planning New Features
When I ask to plan a feature:
1. Create a plan document in /plans/
2. Wait for my approval before making code changes
3. Break down into reviewable chunks
