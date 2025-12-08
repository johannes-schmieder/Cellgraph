# Plan: Expand test_cellgraph.do Test Coverage

## Current State

The existing test file:
- Creates synthetic panel data (good)
- Has an `exit` statement at line 111 that prevents most tests from running
- Tests are visual/manual - no automated pass/fail checks
- Covers: binscatter, controls, cipattern, colors, gradient, multiple statistics

## Recommended Approach

### 1. Create Automated Test Infrastructure

Add a simple test harness that catches errors and reports results:

```stata
// At start of file
local test_count = 0
local fail_count = 0

// Test macro to wrap each test
capture program drop run_test
program define run_test
    syntax, name(string) cmd(string asis)

    c_local test_count = $test_count + 1
    global test_count = $test_count + 1

    capture `cmd'
    if _rc {
        di as error "FAIL: `name' (error code: " _rc ")"
        c_local fail_count = $fail_count + 1
        global fail_count = $fail_count + 1
    }
    else {
        di as result "PASS: `name'"
    }
end

// At end of file
di _n "======================================"
di "Tests run: $test_count"
di "Failures: $fail_count"
di "======================================"
```

### 2. Test Categories to Add

#### A. Basic Functionality (must not break)
| Test | Description | Currently Tested? |
|------|-------------|-------------------|
| Single by-var, single outcome | `cellgraph wage, by(year)` | Partial |
| Two by-vars, single outcome | `cellgraph wage, by(year female)` | Yes |
| Single by-var, multiple outcomes | `cellgraph wage hours, by(year)` | No |
| Two by-vars, multiple outcomes | `cellgraph wage hours, by(year female)` | No |

#### B. Statistics Options
| Test | Description | Currently Tested? |
|------|-------------|-------------------|
| Default (mean) | Implicit mean with CI | Yes |
| Single non-mean stat | `stat(median)` | No |
| Multiple stats | `stat(p10 p50 p90)` | Yes |
| Variance | `stat(var)` | No |
| SD | `stat(sd)` | No |
| Min/Max | `stat(min)` `stat(max)` | No |

#### C. Graph Type Options
| Test | Description | Currently Tested? |
|------|-------------|-------------------|
| Default (connected) | Standard connected plot | Yes |
| Scatter | `scatter` option | Yes |
| Line | `line` option | Yes |
| With lfit | `lfit` option | Yes |
| With 45deg line | `45deg` option | No |

#### D. Confidence Interval Options
| Test | Description | Currently Tested? |
|------|-------------|-------------------|
| Default shaded CI | Default behavior | Yes |
| Lines CI | `cipattern(lines)` | Yes |
| No CI | `noci` | Yes |
| Custom opacity | `ciopacity(50)` | Partial |

#### E. Marker Options
| Test | Description | Currently Tested? |
|------|-------------|-------------------|
| Default markers | Standard symbols | Yes |
| No markers | `nomsymbol` | Yes |
| Custom symbols | `msymbols(triangle diamond)` | No |
| Marker counts | `mcounts` | Yes |
| Marker size | `msize(large)` | No |

#### F. Color Options
| Test | Description | Currently Tested? |
|------|-------------|-------------------|
| Default palette | Built-in colors | Yes |
| Named colors | `colors(cranberry; dkgreen)` | No |
| RGB colors | `colors(128 0 128; 0 128 128)` | Yes |
| Gradient | `gradient` | Yes |

#### G. Line Pattern Options
| Test | Description | Currently Tested? |
|------|-------------|-------------------|
| Default solid | No lpattern option | Yes |
| Enable patterns | `lpattern` | Yes |
| Custom patterns | `lpatterns(dash solid dot)` | No |
| Line width | `lwidth(thick)` | No |

#### H. Binning Options
| Test | Description | Currently Tested? |
|------|-------------|-------------------|
| Binscatter | `binscatter(20)` | Yes |
| Fixed bin width | `bin(5)` | No |
| Bin + lfit | Combined | Yes |
| Bin + coef | Display coefficients | Yes |

#### I. Baseline Normalization
| Test | Description | Currently Tested? |
|------|-------------|-------------------|
| Single by-var baseline | `baseline(2000)` | No |
| Two by-var baseline | `baseline(2000)` with 2 by-vars | No |

#### J. Title/Legend Options
| Test | Description | Currently Tested? |
|------|-------------|-------------------|
| Custom title | `title("My Title")` | Yes |
| No title | `notitle` | No |
| Subtitle | `subtitle("Sub")` | No |
| Y-axis title | `ytitle("Y Label")` | No |
| Add notes | `addnotes` | Yes |
| Sample notes | `samplenotes("N=1000")` | No |
| No notes | `nonotes` | No |
| No date | `nodate` | No |

#### K. Controls Option
| Test | Description | Currently Tested? |
|------|-------------|-------------------|
| Factor controls | `controls(i.industry)` | Yes |
| Continuous controls | `controls(age)` | No |
| Multiple controls | `controls(i.industry age)` | No |

#### L. Weights
| Test | Description | Currently Tested? |
|------|-------------|-------------------|
| Analytic weights | `[aweight=wgt]` | No |
| Frequency weights | `[fweight=wgt]` | No |

#### M. Edge Cases & Error Handling
| Test | Description | Currently Tested? |
|------|-------------|-------------------|
| Missing values in outcome | Should handle gracefully | Partial |
| Missing values in by-var | Should exclude | Partial |
| Empty cells | Some by-var combinations empty | No |
| Single observation cells | Edge case for CI | No |
| >60 categories in 2nd by-var | Should error | No |
| >2 by-variables | Should error | No |
| Multiple stats + 2 by-vars | Should error | No |

#### N. Twoway Passthrough Options
| Test | Description | Currently Tested? |
|------|-------------|-------------------|
| xlabel | `xlabel(2000(5)2020)` | No |
| ylabel | `ylabel(,angle(horizontal))` | Yes |
| xline/yline | `xline(2010)` | Yes |
| legend position | `legend(pos(6))` | Partial |
| Scheme override | `scheme(s1mono)` | No |

### 3. Files That Need Changes

| File | Changes |
|------|---------|
| `test_cellgraph.do` | Add test harness, expand test cases, remove `exit` |

### 4. Implementation Steps

1. **Remove the `exit` statement** at line 111 so all tests run
2. **Add test harness** at top of file with `run_test` program
3. **Reorganize existing tests** to use the harness
4. **Add missing test cases** by category (prioritize A-M above)
5. **Add edge case tests** that verify errors are thrown correctly
6. **Add summary output** at end showing pass/fail counts

### 5. Priority Order

High priority (core functionality):
1. Basic functionality tests (A)
2. Statistics options (B)
3. Edge cases & error handling (M)
4. Baseline normalization (I) - currently untested

Medium priority (common options):
5. Weights (L)
6. Custom markers/patterns (E, G)
7. Title/legend options (J)

Lower priority (less common):
8. Binning edge cases
9. Passthrough options (N)

### 6. Example Test Structure

```stata
// ====== A. Basic Functionality ======
sysuse nlsw88, clear

run_test, name("A1: Single by-var, single outcome") ///
    cmd(cellgraph wage, by(grade) name(test_a1, replace))

run_test, name("A2: Two by-vars, single outcome") ///
    cmd(cellgraph wage, by(grade union) name(test_a2, replace))

run_test, name("A3: Single by-var, multiple outcomes") ///
    cmd(cellgraph wage hours, by(grade) name(test_a3, replace))

// ====== M. Error Cases ======
run_test, name("M1: >2 by-vars should error") ///
    cmd(cellgraph wage, by(grade union race))
// This should increment fail_count since it errors - need inverse logic for expected errors
```
