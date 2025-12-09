# Code Review: cellgraph Stata Package

**Review Date:** 2025-12-08
**Reviewer:** Claude Code
**Version Reviewed:** Current main branch (commit ebbb239)
**Last Updated:** 2025-12-08 (after bug fixes)

---

## Overall Assessment

This is a well-structured, mature Stata package with comprehensive testing. The codebase shows thoughtful design decisions and handles many edge cases. However, there are several areas that could benefit from improvement.


## 2. Code Quality Issues

### Inconsistent variable naming conventions
- Mix of `touse` and `miss` for sample markers
- Mix of `col` and `color`
- `j++` increment used inconsistently (lines 499, 502, 507, 511)

### Repeated code blocks
The two-by-variable and one-by-variable graph construction paths (lines 669-797 vs 799-894) share ~70% similar logic. Consider refactoring to a single parameterized block.

### Magic numbers throughout
- Line 241: `60` categories maximum - should be a configurable option or at least documented constant
- Line 400: `0.05` x-axis padding factor
- Line 709, 744-746: `0.85`, `0.075`, `0.95` for text positioning

---

## 3. Testing Gaps

### Not tested
- `gtools` and `ftools` options (require those packages)
- Very long category labels causing layout issues
- Interaction of `baseline()` with `xorder()`
- `lfit coef` with non-mean statistics (currently silently fails at line 765)
- Unicode characters in labels
- Extreme `ciopacity` values (0, 100, negative)

### Data verification tests (T1-T5) and new tests (I5-I6, K5)
These are excellent additions. Now verifying:
- ✓ The `baseline()` transformation (I5, I6)
- ✓ `controls()` basic functionality (K5)
- Could also verify: `controls()` residualization details, weighted statistics match manual weighted collapse

### Test harness improvement suggestion
```stata
// Current: run_test just checks pass/fail
// Better: capture actual output and compare expected values
```

---

## 4. API Design Suggestions

### Inconsistent option naming
- `noci` vs `nomsymbol` vs `nonotes` vs `notitle` - inconsistent prefix (`no` vs `no-`word)
- `cipattern()` but `lpatterns()` (plural inconsistency)
- `colors()` takes semicolons but `msymbols()` takes spaces

### Missing options that users might expect
- `replace` for graph name (currently errors if graph exists)
- `level()` for confidence interval level (instead of hard-coded 95%)
- `scheme()` pass-through
- `by2colors()` / `by2labels()` for finer control of second by-variable

### Consider deprecating
- `lpattern` boolean in favor of only `lpatterns()` with a default value

---

## 5. Documentation Issues

### Help file (cellgraph.sthlp)
- No example showing `controls()` option (requires reghdfe)
- No example showing `baseline()` normalization
- No example showing `saving()` option
- Example 5 description says "Two Outcomes, two statistics" but code only has one outcome

### Inline comments
- Many sections lack explanatory comments (e.g., the coefficient text positioning logic at lines 783-795)
- The graph construction section (lines 662-894) is 230+ lines without section markers

---

## 6. Architecture Suggestions

### Consider extracting helper programs
```stata
// Candidate extractions:
__build_graph_single_by    // Lines 669-797
__build_graph_two_by       // Lines 799-894
__apply_baseline           // Lines 517-583
__apply_xorder             // Lines 585-648
```

### State management
The command modifies global state via the graph. Consider returning values in `r()` for programmatic use:

```stata
return scalar N = `N'
return local collapsed_vars "`varlist'"
return local by_vars "`by'"
```

---

## 7. Minor Issues

### Line 962 - Only shows last variable in varlist
```stata
list `by' *`v'*  // `v' is only the last var from the foreach loop
```
Should likely be `*wage* *hours*` etc for multiple outcomes.

### Inefficient levelsof calls
Lines 352, 370, 523, 554 call `levelsof` but the values are already available from earlier `tab` calls.

### Version compatibility claims
- Header says version 12.0, `.pkg` says Stata 14+, comments say "mostly tested with Stata 18"
- Consider either properly testing on Stata 14-17 or bumping minimum version

---

## 8. Security/Robustness

### File path handling
**Location:** [cellgraph.ado:967](cellgraph.ado#L967)

```stata
qui save `"`savefile'"', `savereplace'
```

The `savefile` is user-provided. While Stata's `save` is generally safe, consider validating the path doesn't contain unexpected characters.

### No check for sufficient observations per cell
If a cell has only 1 observation, CI calculation will produce missing values. Consider warning the user.

---

## Summary of Remaining Issues

| Priority | Issue | Location |
|----------|-------|----------|
| :yellow_circle: Medium | `list` only shows last var | Line 958 |
| :green_circle: Low | Refactor duplicate graph code | Lines 665-890 |

---

## Conclusion

This is a solid package with comprehensive testing (137 tests, all passing). The two high-priority bugs (baseline CI normalization and `controls()` undefined variable) have been fixed and verified with new tests (I5, I6, K5). Dead code in the binning section has also been cleaned up. The remaining issues are medium/low priority improvements that would benefit the codebase but do not affect core functionality.
