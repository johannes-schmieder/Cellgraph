# Plan: Add `saving()` Option to Save Collapsed Data

## Overview

Add a new option that saves the collapsed cell-level data to a file, similar to how the existing `list` option displays it. This allows users to export the aggregated data for further analysis.

## Option Design

**Name:** `saving(filename [, replace])`

This follows Stata conventions (e.g., `graph export`, `estimates save`). The optional `replace` suboption allows overwriting existing files.

**Syntax example:**
```stata
cellgraph price mpg, by(foreign) saving(collapsed_data.dta, replace)
```

## Implementation Steps

### 1. Add option to syntax (line ~40)

Add after the `list` option:
```stata
SAVing(str)             /// save collapsed data to a file.
```

### 2. Parse the saving option (after line ~170)

Parse the filename and `replace` suboption:
```stata
// Parse saving option
if `"`saving'"' != "" {
    local 0 `"`saving'"'
    syntax anything(name=savefile) [, replace]
}
```

### 3. Save data before restore (around line 930-933)

Add the save command right after the `list` block, before `restore`:
```stata
if "`list'"!="" {
    list `by' *`v'*  , clean noo div
}

// Save collapsed data if requested
if `"`savefile'"' != "" {
    qui save `"`savefile'"', `replace'
}

restore
```

## Variables Saved

The saved dataset will contain:
- **By-variables:** The grouping variables (`by`)
- **For each outcome variable `v`:**
  - `obs{v}` - observation count per cell
  - `sd{v}` - standard deviation per cell
  - `{v}_{stat}` - the computed statistic (e.g., `{v}_mean`, `{v}_p50`)
  - `{v}hi`, `{v}lo` - confidence interval bounds (if stat=mean)

## Files to Modify

1. **cellgraph.ado** - Add option parsing and save command
2. **cellgraph.sthlp** - Document the new option with an example

## Testing

Add test case to `test_cellgraph.do`:
```stata
// Test saving option
sysuse auto, clear
cellgraph price mpg, by(foreign) saving(test_save.dta, replace)
use test_save.dta, clear
assert _N == 2  // two groups: foreign=0, foreign=1
list
erase test_save.dta
```

## Chunk Breakdown

1. **Chunk 1:** Add syntax and parsing in cellgraph.ado
2. **Chunk 2:** Add save logic before restore
3. **Chunk 3:** Update help file with documentation
4. **Chunk 4:** Add test case
