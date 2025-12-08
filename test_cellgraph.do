// ================================================
// ===== Automated Test Suite for cellgraph.ado =====
// ================================================
// Run with: do test_cellgraph.do
// Tests will report PASS/FAIL and provide summary at end

clear all
set more off
set seed 12345
program drop _all
graph drop _all

// Source the ado file
do cellgraph.ado

// ====== Test Harness ======
global test_count = 0
global pass_count = 0
global fail_count = 0

capture program drop run_test
program define run_test
    syntax, name(string) [cmd(string asis) expect_error]

    global test_count = $test_count + 1

    capture noisily `cmd'
    local rc = _rc

    if "`expect_error'" != "" {
        // We expected an error
        if `rc' != 0 {
            di as result "PASS: `name' (expected error, got rc=`rc')"
            global pass_count = $pass_count + 1
        }
        else {
            di as error "FAIL: `name' (expected error but succeeded)"
            global fail_count = $fail_count + 1
        }
    }
    else {
        // We expected success
        if `rc' == 0 {
            di as result "PASS: `name'"
            global pass_count = $pass_count + 1
        }
        else {
            di as error "FAIL: `name' (error code: `rc')"
            global fail_count = $fail_count + 1
        }
    }

    // Clean up graphs to avoid memory issues
    capture graph drop _all
end

// ====== Create Test Data: Panel Dataset ======
di _n as txt "Creating test panel data..."

local N = 500
local tmin = 2000
local tmax = 2010
local rows = `N' * (`tmax' - `tmin' + 1)
set obs `rows'

// Generate person and year identifiers
gen person_id = ceil(_n/(`tmax' - `tmin' + 1))
bysort person_id: gen year = `tmin' + _n - 1

// Randomly drop some observations to create unbalanced panel (about 20%)
gen random = runiform()
drop if random < 0.2
drop random

// Generate time-invariant characteristics
by person_id: gen female = runiform() < 0.45 if _n == 1
by person_id: replace female = female[1] if _n > 1

// Generate age (starting between 25-45 in 2000)
by person_id: gen age = ceil(runiform() * 20 + 25) if year == `tmin'
by person_id: replace age = age[_n-1] + 1 if _n > 1

// Generate education (between 12-20 years, time-invariant)
by person_id: gen educ = ceil(runiform() * 8 + 12) if _n == 1
by person_id: replace educ = educ[1] if _n > 1

// Generate industry (1-5)
by person_id: gen industry = ceil(runiform() * 5) if _n == 1
by person_id: replace industry = industry[_n-1] if _n > 1
replace industry = ceil(runiform() * 5) if runiform() < 0.1

// Generate continuous outcome
gen experience = age - educ - 6
gen logwage = 1.5 + 0.08 * educ + 0.12 * experience - 0.002 * experience^2 ///
    - 0.15 * female + 0.1 * industry + rnormal(0, 0.3)
gen wage = exp(logwage)
gen hours = 35 + 10*runiform() + 5*female

// Generate weight variable for weight tests
gen wgt = 1 + runiform()

// Generate birth year for additional by-var
gen byear = year - age

// Labels
label var person_id "Person identifier"
label var year "Year"
label var age "Age in years"
label var educ "Years of education"
label var logwage "Log hourly wage"
label var wage "Hourly wage"
label var hours "Hours worked"
label var female "Female (0/1)"
label var industry "Industry (1-5)"
label var experience "Years of potential experience"
label var byear "Birth Year"
label var wgt "Sample weight"

label define ind_label 1 "Manufacturing" 2 "Services" 3 "Retail" 4 "Technology" 5 "Finance"
label values industry ind_label
label define female_label 0 "Male" 1 "Female"
label values female female_label

sort person_id year
tempfile panel_data
save `panel_data'

di as txt "Test data created: " _N " observations"
di _n as txt "========================================"
di as txt "Starting Automated Tests"
di as txt "========================================"

// ============================================================
// A. BASIC FUNCTIONALITY TESTS
// ============================================================
di _n as txt "=== A. Basic Functionality ===" _n

run_test, name("A1: Single by-var, single outcome") ///
    cmd(cellgraph wage, by(year))

run_test, name("A2: Two by-vars, single outcome") ///
    cmd(cellgraph wage, by(year female))

run_test, name("A3: Single by-var, multiple outcomes") ///
    cmd(cellgraph wage hours, by(year))

run_test, name("A4: Two by-vars, multiple outcomes") ///
    cmd(cellgraph wage hours, by(year female))

run_test, name("A5: With if condition") ///
    cmd(cellgraph wage if year >= 2005, by(year))

run_test, name("A6: With in range") ///
    cmd(cellgraph wage in 1/1000, by(year))

run_test, name("A7: Graph name option") ///
    cmd(cellgraph wage, by(year) name(test_graph))

// ============================================================
// B. STATISTICS OPTIONS TESTS
// ============================================================
di _n as txt "=== B. Statistics Options ===" _n

run_test, name("B1: Default mean") ///
    cmd(cellgraph wage, by(year))

run_test, name("B2: Explicit mean") ///
    cmd(cellgraph wage, by(year) stat(mean))

run_test, name("B3: Median") ///
    cmd(cellgraph wage, by(year) stat(median))

run_test, name("B4: Standard deviation") ///
    cmd(cellgraph wage, by(year) stat(sd))

run_test, name("B5: Variance") ///
    cmd(cellgraph wage, by(year) stat(var))

run_test, name("B6: Min") ///
    cmd(cellgraph wage, by(year) stat(min))

run_test, name("B7: Max") ///
    cmd(cellgraph wage, by(year) stat(max))

run_test, name("B8: Sum") ///
    cmd(cellgraph wage, by(year) stat(sum))

run_test, name("B9: Percentile p10") ///
    cmd(cellgraph wage, by(year) stat(p10))

run_test, name("B10: Percentile p50") ///
    cmd(cellgraph wage, by(year) stat(p50))

run_test, name("B11: Percentile p90") ///
    cmd(cellgraph wage, by(year) stat(p90))

run_test, name("B12: Multiple percentiles") ///
    cmd(cellgraph wage, by(year) stat(p10 p50 p90))

run_test, name("B13: Mixed statistics") ///
    cmd(cellgraph wage, by(year) stat(mean median))

// ============================================================
// C. GRAPH TYPE TESTS
// ============================================================
di _n as txt "=== C. Graph Type Options ===" _n

run_test, name("C1: Default connected") ///
    cmd(cellgraph wage, by(year))

run_test, name("C2: Scatter plot") ///
    cmd(cellgraph wage, by(year) scatter)

run_test, name("C3: Line plot") ///
    cmd(cellgraph wage, by(year) line)

run_test, name("C4: With linear fit") ///
    cmd(cellgraph wage, by(year) lfit noci)

run_test, name("C5: With coefficients displayed") ///
    cmd(cellgraph wage, by(year) coef lfit noci)

run_test, name("C6: With 45-degree line") ///
    cmd(cellgraph logwage, by(educ) 45deg noci)

run_test, name("C7: Scatter with lfit and coef") ///
    cmd(cellgraph wage, by(year) scatter lfit coef noci)

// ============================================================
// D. CONFIDENCE INTERVAL TESTS
// ============================================================
di _n as txt "=== D. Confidence Interval Options ===" _n

run_test, name("D1: Default shaded CI") ///
    cmd(cellgraph wage, by(year))

run_test, name("D2: Lines CI pattern") ///
    cmd(cellgraph wage, by(year) cipattern(lines))

run_test, name("D3: Shaded CI pattern explicit") ///
    cmd(cellgraph wage, by(year) cipattern(shaded))

run_test, name("D4: No CI") ///
    cmd(cellgraph wage, by(year) noci)

run_test, name("D5: CI opacity 10") ///
    cmd(cellgraph wage, by(year) ciopacity(10))

run_test, name("D6: CI opacity 50") ///
    cmd(cellgraph wage, by(year) ciopacity(50))

run_test, name("D7: CI opacity 80") ///
    cmd(cellgraph wage, by(year) ciopacity(80))

run_test, name("D8: Two by-vars with CI") ///
    cmd(cellgraph wage, by(year female))

run_test, name("D9: Two by-vars with lines CI") ///
    cmd(cellgraph wage, by(year female) cipattern(lines))

// ============================================================
// E. MARKER OPTIONS TESTS
// ============================================================
di _n as txt "=== E. Marker Options ===" _n

run_test, name("E1: Default markers") ///
    cmd(cellgraph wage, by(year) noci)

run_test, name("E2: No markers") ///
    cmd(cellgraph wage, by(year) nomsymbol noci)

run_test, name("E3: Custom marker symbols") ///
    cmd(cellgraph wage, by(year female) msymbols(triangle diamond) noci)

run_test, name("E4: Marker counts") ///
    cmd(cellgraph wage, by(year) mcounts noci)

run_test, name("E5: Marker counts with two by-vars") ///
    cmd(cellgraph wage, by(year female) mcounts noci)

run_test, name("E6: Marker size small") ///
    cmd(cellgraph wage, by(year) msize(small) noci)

run_test, name("E7: Marker size large") ///
    cmd(cellgraph wage, by(year) msize(large) noci)

// ============================================================
// F. COLOR OPTIONS TESTS
// ============================================================
di _n as txt "=== F. Color Options ===" _n

run_test, name("F1: Default colors") ///
    cmd(cellgraph wage, by(year female) noci)

run_test, name("F2: Named colors semicolon-separated") ///
    cmd(cellgraph wage, by(year female) colors(cranberry; dkgreen) noci)

run_test, name("F3: RGB colors") ///
    cmd(cellgraph wage, by(year female) colors(128 0 128; 0 128 128) noci)

run_test, name("F4: Single named color") ///
    cmd(cellgraph wage, by(year) colors(maroon) noci)

run_test, name("F5: Gradient option") ///
    cmd(cellgraph wage, by(year female) gradient noci)

run_test, name("F6: Gradient with multiple stats") ///
    cmd(cellgraph wage, by(year) stat(p10 p25 p50 p75 p90) gradient)

// ============================================================
// G. LINE PATTERN TESTS
// ============================================================
di _n as txt "=== G. Line Pattern Options ===" _n

run_test, name("G1: Enable line patterns") ///
    cmd(cellgraph wage, by(year female) lpattern noci)

run_test, name("G2: Custom line patterns") ///
    cmd(cellgraph wage, by(year female) lpatterns(dash solid) noci)

run_test, name("G3: Line width thin") ///
    cmd(cellgraph wage, by(year) lwidth(thin) noci)

run_test, name("G4: Line width thick") ///
    cmd(cellgraph wage, by(year) lwidth(thick) noci)

run_test, name("G5: Patterns with line plot") ///
    cmd(cellgraph wage, by(year female) line lpattern noci)

// ============================================================
// H. BINNING OPTIONS TESTS
// ============================================================
di _n as txt "=== H. Binning Options ===" _n

run_test, name("H1: Binscatter 10 bins") ///
    cmd(cellgraph wage, by(age) binscatter(10) noci)

run_test, name("H2: Binscatter 20 bins") ///
    cmd(cellgraph wage, by(age) binscatter(20) noci)

run_test, name("H3: Binscatter with scatter") ///
    cmd(cellgraph wage, by(age) binscatter(15) scatter noci)

run_test, name("H4: Binscatter with lfit") ///
    cmd(cellgraph wage, by(age) binscatter(20) lfit noci)

run_test, name("H5: Binscatter with coef") ///
    cmd(cellgraph wage, by(age) binscatter(20) lfit coef noci)

run_test, name("H6: Fixed bin width") ///
    cmd(cellgraph wage, by(age) bin(5) noci)

run_test, name("H7: Binscatter with two by-vars") ///
    cmd(cellgraph wage, by(age female) binscatter(10) noci)

run_test, name("H8: Binscatter scatter lfit coef combined") ///
    cmd(cellgraph wage, by(age) binscatter(20) scatter lfit coef noci)

// ============================================================
// I. BASELINE NORMALIZATION TESTS
// ============================================================
di _n as txt "=== I. Baseline Normalization ===" _n

run_test, name("I1: Baseline with single by-var") ///
    cmd(cellgraph wage, by(year) baseline(2000))

run_test, name("I2: Baseline with two by-vars") ///
    cmd(cellgraph wage, by(year female) baseline(2000))

run_test, name("I3: Baseline middle value") ///
    cmd(cellgraph wage, by(year) baseline(2005))

run_test, name("I4: Baseline with noci") ///
    cmd(cellgraph wage, by(year) baseline(2000) noci)

// ============================================================
// J. TITLE AND LEGEND OPTIONS TESTS
// ============================================================
di _n as txt "=== J. Title and Legend Options ===" _n

run_test, name("J1: Custom title") ///
    cmd(cellgraph wage, by(year) title("My Custom Title") noci)

run_test, name("J2: No title") ///
    cmd(cellgraph wage, by(year) notitle noci)

run_test, name("J3: Subtitle") ///
    cmd(cellgraph wage, by(year) subtitle("A subtitle") noci)

run_test, name("J4: Y-axis title") ///
    cmd(cellgraph wage, by(year) ytitle("Hourly Wage ($)") noci)

run_test, name("J5: Add notes") ///
    cmd(cellgraph wage, by(year) addnotes noci)

run_test, name("J6: Sample notes") ///
    cmd(cellgraph wage, by(year) samplenotes("Sample: Full-time workers") noci)

run_test, name("J7: No notes") ///
    cmd(cellgraph wage, by(year) nonotes noci)

run_test, name("J8: No date in notes") ///
    cmd(cellgraph wage, by(year) addnotes nodate noci)

run_test, name("J9: Combined title options") ///
    cmd(cellgraph wage, by(year) title("Main") subtitle("Sub") ytitle("Y") noci)

// ============================================================
// K. CONTROLS OPTION TESTS (requires reghdfe)
// ============================================================
di _n as txt "=== K. Controls Option ===" _n

// Check if reghdfe is installed
capture which reghdfe
if _rc == 0 {
    run_test, name("K1: Factor controls") ///
        cmd(cellgraph wage, by(year) controls(i.industry) noci)

    run_test, name("K2: Continuous controls") ///
        cmd(cellgraph wage, by(year) controls(age) noci)

    run_test, name("K3: Multiple controls") ///
        cmd(cellgraph wage, by(year) controls(i.industry age) noci)

    run_test, name("K4: Controls with binscatter") ///
        cmd(cellgraph wage, by(age) controls(i.industry) binscatter(20) noci)
}
else {
    di as txt "SKIP: K1-K4 (reghdfe not installed)"
}

// ============================================================
// L. WEIGHTS TESTS
// ============================================================
di _n as txt "=== L. Weights ===" _n

run_test, name("L1: Analytic weights") ///
    cmd(cellgraph wage [aweight=wgt], by(year) noci)

run_test, name("L2: Frequency weights") ///
    cmd(cellgraph wage [fweight=round(wgt*10)], by(year) noci)

run_test, name("L3: Aweights with two by-vars") ///
    cmd(cellgraph wage [aweight=wgt], by(year female) noci)

// ============================================================
// M. EDGE CASES AND ERROR HANDLING TESTS
// ============================================================
di _n as txt "=== M. Edge Cases and Error Handling ===" _n

// Expected errors
run_test, name("M1: >2 by-vars should error") ///
    cmd(cellgraph wage, by(year female industry)) expect_error

run_test, name("M2: Multiple stats + 2 by-vars should error") ///
    cmd(cellgraph wage, by(year female) stat(mean median)) expect_error

run_test, name("M3: Invalid cipattern should error") ///
    cmd(cellgraph wage, by(year) cipattern(invalid)) expect_error

// Edge cases that should work
run_test, name("M4: Missing values in outcome") ///
    cmd(cellgraph age, by(year) noci)

preserve
replace wage = . if runiform() < 0.3
run_test, name("M5: Many missing values in outcome") ///
    cmd(cellgraph wage, by(year) noci)
restore

// Small sample
preserve
keep if _n <= 100
run_test, name("M6: Small sample") ///
    cmd(cellgraph wage, by(year) noci)
restore

// ============================================================
// N. TWOWAY PASSTHROUGH OPTIONS TESTS
// ============================================================
di _n as txt "=== N. Twoway Passthrough Options ===" _n

run_test, name("N1: Custom xlabel") ///
    cmd(cellgraph wage, by(year) xlabel(2000(2)2010) noci)

run_test, name("N2: Custom ylabel") ///
    cmd(cellgraph wage, by(year) ylabel(,angle(horizontal)) noci)

run_test, name("N3: Xline") ///
    cmd(cellgraph wage, by(year) xline(2005) noci)

run_test, name("N4: Yline") ///
    cmd(cellgraph wage, by(year) yline(10) noci)

run_test, name("N5: Legend position") ///
    cmd(cellgraph wage, by(year female) legend(pos(3)) noci)

run_test, name("N6: Legend off") ///
    cmd(cellgraph wage, by(year female) legend(off) noci)

run_test, name("N7: Legend columns") ///
    cmd(cellgraph wage, by(year female) legend(col(1)) noci)

run_test, name("N8: Yscale range") ///
    cmd(cellgraph wage, by(year) yscale(range(0 20)) noci)

run_test, name("N9: Combined passthrough options") ///
    cmd(cellgraph wage, by(year) xlabel(2000(2)2010) ylabel(,angle(0)) xline(2005) noci)

// ============================================================
// O. LIST OPTION TEST
// ============================================================
di _n as txt "=== O. List Option ===" _n

run_test, name("O1: List collapsed data") ///
    cmd(cellgraph wage, by(year) list noci)

// ============================================================
// P. COMBINATION TESTS (realistic use cases)
// ============================================================
di _n as txt "=== P. Combination Tests ===" _n

run_test, name("P1: Binscatter publication style") ///
    cmd(cellgraph wage, by(age) binscatter(20) scatter lfit coef noci ///
        title("Wage-Age Profile") ytitle("Hourly Wage") legend(off))

run_test, name("P2: Time series with CI") ///
    cmd(cellgraph wage, by(year female) cipattern(shaded) ciopacity(20) ///
        lpattern title("Wages by Year and Gender") addnotes)

run_test, name("P3: Multiple percentiles gradient") ///
    cmd(cellgraph wage, by(year) stat(p10 p25 p50 p75 p90) gradient ///
        nomsymbol lpattern title("Wage Distribution Over Time"))

run_test, name("P4: Normalized to baseline") ///
    cmd(cellgraph logwage, by(year female) baseline(2000) ///
        title("Log Wage Growth Relative to 2000"))

run_test, name("P5: Line plot no markers") ///
    cmd(cellgraph wage, by(year female) line nomsymbol lpattern ///
        colors(navy; maroon) noci)

// ============================================================
// SUMMARY
// ============================================================
di _n as txt "========================================"
di as txt "TEST SUMMARY"
di as txt "========================================"
di as txt "Total tests:  " as result $test_count
di as txt "Passed:       " as result $pass_count
di as txt "Failed:       " as error $fail_count
di as txt "========================================"

if $fail_count > 0 {
    di as error "SOME TESTS FAILED - Review output above"
    exit 1
}
else {
    di as result "ALL TESTS PASSED"
}
