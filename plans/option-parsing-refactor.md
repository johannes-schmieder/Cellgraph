# Plan: Refactor Fragile Option Parsing

## Problem

The code uses a save/restore pattern around `syntax` calls to prevent sub-option parsing from clobbering the main command's locals:

```stata
// Lines 183-191: saving() option
local __save_varlist "`varlist'"
local __save_stat "`stat'"
local 0 `"`saving'"'
syntax anything(name=savefile) [, replace]
local varlist "`__save_varlist'"
local stat "`__save_stat'"

// Lines 207-215: xorder() suboptions
local __save_varlist "`varlist'"
local __save_stat "`stat'"
syntax , [Descending Stat(str)]
local varlist "`__save_varlist'"
local stat "`__save_stat'"
```

This pattern is:
- **Repetitive** - Same 4 lines appear twice
- **Error-prone** - Easy to forget restoration or save the wrong locals
- **Fragile** - Adding new locals to main syntax requires updating all save/restore blocks

## Proposed Solution

Create helper programs that parse sub-options in isolated namespaces, returning results via `sreturn`. This leverages Stata's program-local scoping.

### Implementation

#### 1. Add helper program `__parse_saving`

```stata
program define __parse_saving, sclass
    syntax anything(name=savefile) [, replace]
    sreturn local savefile `"`savefile'"'
    sreturn local savereplace "`replace'"
end
```

#### 2. Add helper program `__parse_xorder_opts`

```stata
program define __parse_xorder_opts, sclass
    syntax , [Descending Stat(str)]
    sreturn local descending = ("`descending'" == "descending")
    sreturn local stat "`stat'"
end
```

#### 3. Simplify calling code

**Before (saving):**
```stata
if `"`saving'"' != "" {
    local __save_varlist "`varlist'"
    local __save_stat "`stat'"
    local 0 `"`saving'"'
    syntax anything(name=savefile) [, replace]
    local savereplace "`replace'"
    local varlist "`__save_varlist'"
    local stat "`__save_stat'"
}
```

**After (saving):**
```stata
if `"`saving'"' != "" {
    __parse_saving `saving'
    local savefile `"`s(savefile)'"'
    local savereplace "`s(savereplace)'"
}
```

**Before (xorder):**
```stata
if `"`xorder_opts'"' != "" {
    local xorder_opts = subinstr(`"`xorder_opts'"', ",", "", 1)
    local 0 , `xorder_opts'
    local __save_varlist "`varlist'"
    local __save_stat "`stat'"
    syntax , [Descending Stat(str)]
    if "`descending'" == "descending" local xorder_desc = 1
    if "`stat'" != "" local xorder_stat "`stat'"
    local varlist "`__save_varlist'"
    local stat "`__save_stat'"
}
```

**After (xorder):**
```stata
if `"`xorder_opts'"' != "" {
    local xorder_opts = subinstr(`"`xorder_opts'"', ",", "", 1)
    __parse_xorder_opts , `xorder_opts'
    local xorder_desc = `s(descending)'
    if "`s(stat)'" != "" local xorder_stat "`s(stat)'"
}
```

## Benefits

1. **Isolated namespaces** - Helper programs have their own locals; no clobbering possible
2. **DRY principle** - No repeated save/restore boilerplate
3. **Maintainable** - Adding new main syntax locals doesn't affect sub-parsing
4. **Testable** - Helper programs can be unit tested independently
5. **Idiomatic** - Uses Stata's standard `sreturn` mechanism for returning values

## Testing

1. Run existing test suite: `do test_cellgraph.do`
2. Verify `saving()` option works correctly with various inputs
3. Verify `xorder()` option with all suboption combinations
4. Test edge cases:
   - `saving("file with spaces.dta")`
   - `saving(file, replace)`
   - `xorder(var, descending stat(median))`

## Risks

- **Low risk**: Helper programs add minimal overhead (one program call vs inline code)
- Uses well-established Stata patterns (`sclass` programs with `sreturn`)

## Files to Modify

- [cellgraph.ado](../cellgraph.ado) - Lines 180-216
