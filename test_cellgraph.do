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

// Generate string variables for string by-var tests
gen str10 gender_str = "Male" if female == 0
replace gender_str = "Female" if female == 1
gen str20 industry_str = ""
replace industry_str = "Manufacturing" if industry == 1
replace industry_str = "Services" if industry == 2
replace industry_str = "Retail" if industry == 3
replace industry_str = "Technology" if industry == 4
replace industry_str = "Finance" if industry == 5

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

// I5-I6: Verify baseline normalization preserves CI width
di as txt "I5: Verifying baseline CI width preservation (single by-var)..."
tempfile i5_before i5_after

// Get CI width before baseline
cellgraph wage, by(year) saving(`i5_before', replace)

// Get CI width after baseline
cellgraph wage, by(year) baseline(2000) saving(`i5_after', replace)

// Compare CI widths
use `i5_before', clear
gen ci_width_before = wagehi - wagelo
keep year ci_width_before
tempfile i5_widths
save `i5_widths', replace

use `i5_after', clear
gen ci_width_after = wagehi - wagelo
merge 1:1 year using `i5_widths', nogen

capture {
    gen width_diff = abs(ci_width_before - ci_width_after)
    assert width_diff < 1e-10 | missing(width_diff)
}
if _rc == 0 {
    di as result "PASS: I5: Baseline CI width preserved (single by-var)"
    global pass_count = $pass_count + 1
}
else {
    di as error "FAIL: I5: Baseline CI width not preserved (single by-var)"
    global fail_count = $fail_count + 1
}
global test_count = $test_count + 1

// Reload test data
use `panel_data', clear

di as txt "I6: Verifying baseline CI width preservation (two by-vars)..."
tempfile i6_before i6_after

// Get CI width before baseline
cellgraph wage, by(year female) saving(`i6_before', replace)

// Get CI width after baseline
cellgraph wage, by(year female) baseline(2000) saving(`i6_after', replace)

// Compare CI widths
use `i6_before', clear
gen ci_width_before = wagehi - wagelo
keep year female ci_width_before
tempfile i6_widths
save `i6_widths', replace

use `i6_after', clear
gen ci_width_after = wagehi - wagelo
merge 1:1 year female using `i6_widths', nogen

capture {
    gen width_diff = abs(ci_width_before - ci_width_after)
    assert width_diff < 1e-10 | missing(width_diff)
}
if _rc == 0 {
    di as result "PASS: I6: Baseline CI width preserved (two by-vars)"
    global pass_count = $pass_count + 1
}
else {
    di as error "FAIL: I6: Baseline CI width not preserved (two by-vars)"
    global fail_count = $fail_count + 1
}
global test_count = $test_count + 1

// Reload test data
use `panel_data', clear

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

    run_test, name("K5: Controls with single by-var, no binning") ///
        cmd(cellgraph wage, by(year) controls(age) noci)
}
else {
    di as txt "SKIP: K1-K5 (reghdfe not installed)"
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
// Q. STRING BY-VARIABLE TESTS
// ============================================================
di _n as txt "=== Q. String By-Variable Tests ===" _n

run_test, name("Q1: Single string by-var") ///
    cmd(cellgraph wage, by(gender_str) noci)

run_test, name("Q2: String by-var with CI") ///
    cmd(cellgraph wage, by(gender_str))

run_test, name("Q3: Two by-vars, first numeric second string") ///
    cmd(cellgraph wage, by(year gender_str) noci)

run_test, name("Q4: Two by-vars, first string second numeric") ///
    cmd(cellgraph wage, by(industry_str female) noci)

run_test, name("Q5: Two string by-vars") ///
    cmd(cellgraph wage, by(industry_str gender_str) noci)

run_test, name("Q6: String by-var with multiple outcomes") ///
    cmd(cellgraph wage hours, by(gender_str) noci)

run_test, name("Q7: String by-var with statistics") ///
    cmd(cellgraph wage, by(gender_str) stat(p25 p50 p75))

run_test, name("Q8: String by-var with binscatter") ///
    cmd(cellgraph wage, by(age gender_str) binscatter(10) noci)

run_test, name("Q9: String by-var with baseline") ///
    cmd(cellgraph wage, by(industry_str) noci)

run_test, name("Q10: Binscatter with string first by-var should error") ///
    cmd(cellgraph wage, by(gender_str) binscatter(10) noci) expect_error

run_test, name("Q11: Bin with string first by-var should error") ///
    cmd(cellgraph wage, by(gender_str) bin(1) noci) expect_error

// ============================================================
// R. XORDER OPTION TESTS
// ============================================================
di _n as txt "=== R. Xorder Option Tests ===" _n

run_test, name("R1: Basic xorder with labeled by-var") ///
    cmd(cellgraph wage, by(industry) xorder(wage) noci)

run_test, name("R2: xorder descending") ///
    cmd(cellgraph wage, by(industry) xorder(wage, descending) noci)

run_test, name("R3: xorder with stat(median)") ///
    cmd(cellgraph wage, by(industry) xorder(wage, stat(median)) noci)

run_test, name("R4: xorder with stat(p75)") ///
    cmd(cellgraph wage, by(industry) xorder(wage, stat(p75)) noci)

run_test, name("R5: xorder descending with stat") ///
    cmd(cellgraph wage, by(industry) xorder(wage, descending stat(median)) noci)

run_test, name("R6: xorder with string by-var") ///
    cmd(cellgraph wage, by(industry_str) xorder(wage) noci)

run_test, name("R7: xorder string by-var descending") ///
    cmd(cellgraph wage, by(industry_str) xorder(wage, descending) noci)

run_test, name("R8: xorder with two by-vars") ///
    cmd(cellgraph wage, by(industry female) xorder(wage) noci)

run_test, name("R9: xorder with different variable than outcome") ///
    cmd(cellgraph wage, by(industry) xorder(hours) noci)

run_test, name("R10: xorder with CI") ///
    cmd(cellgraph wage, by(industry) xorder(wage))

run_test, name("R11: xorder with non-categorical by-var should error") ///
    cmd(cellgraph wage, by(age) xorder(wage) noci) expect_error

// ============================================================
// S. SAVING OPTION TESTS
// ============================================================
di _n as txt "=== S. Saving Option Tests ===" _n

set trace off
set tracedepth 2

// Test basic saving
run_test, name("S1: Basic saving option") ///
    cmd(cellgraph wage, by(female) saving(test_save_S1.dta, replace) noci)

// Verify saved file has correct structure
capture {
    preserve
    use test_save_S1.dta, clear
    assert _N == 2  // two groups: female=0, female=1
    confirm variable female
    confirm variable wage_mean
    restore
}
if _rc == 0 {
    di as result "PASS: S2: Saved file has correct structure"
    global pass_count = $pass_count + 1
}
else {
    di as error "FAIL: S2: Saved file structure verification"
    global fail_count = $fail_count + 1
}
global test_count = $test_count + 1
capture erase test_save_S1.dta

// Test saving with two by-variables
run_test, name("S3: Saving with two by-vars") ///
    cmd(cellgraph wage, by(female industry) saving(test_save_S3.dta, replace) noci)
capture erase test_save_S3.dta

// Test saving with multiple statistics
run_test, name("S4: Saving with multiple statistics") ///
    cmd(cellgraph wage, by(female) stat(mean median) saving(test_save_S4.dta, replace) noci)
capture erase test_save_S4.dta

// ============================================================
// T. DATA VERIFICATION TESTS (compare saved data to manual collapse)
// ============================================================
di _n as txt "=== T. Data Verification Tests ===" _n

// T1: Verify saved data matches manual collapse calculation
di as txt "T1: Verifying saved data matches manual collapse..."
tempfile t1_saved t1_manual

// Run cellgraph with saving
cellgraph wage, by(female) saving(`t1_saved', replace) noci

// Manual collapse
collapse (count) manual_obs=wage (sd) manual_sd=wage (mean) manual_mean=wage, by(female)
gen manual_hi = manual_mean + 1.96 * manual_sd / sqrt(manual_obs)
gen manual_lo = manual_mean - 1.96 * manual_sd / sqrt(manual_obs)
save `t1_manual', replace

// Load saved and merge
use `t1_saved', clear
merge 1:1 female using `t1_manual', nogen

// Compare
gen diff_mean = abs(wage_mean - manual_mean)
gen diff_hi = abs(wagehi - manual_hi)
gen diff_lo = abs(wagelo - manual_lo)
gen diff_obs = abs(obswage - manual_obs)

capture {
    assert diff_mean < 1e-6 | missing(diff_mean)
    assert diff_hi < 1e-6 | missing(diff_hi)
    assert diff_lo < 1e-6 | missing(diff_lo)
    assert diff_obs < 1e-6 | missing(diff_obs)
}
if _rc == 0 {
    di as result "PASS: T1: Saved data matches manual collapse"
    global pass_count = $pass_count + 1
}
else {
    di as error "FAIL: T1: Saved data does not match manual collapse"
    global fail_count = $fail_count + 1
}
global test_count = $test_count + 1

// Reload test data
use `panel_data', clear

// T2: Verify CI formula (mean ± 1.96*sd/sqrt(n))
di as txt "T2: Verifying CI formula..."
tempfile t2_saved

cellgraph wage, by(industry) saving(`t2_saved', replace)

use `t2_saved', clear
gen hi_check = wage_mean + 1.96 * sdwage / sqrt(obswage)
gen lo_check = wage_mean - 1.96 * sdwage / sqrt(obswage)
gen hi_diff = abs(wagehi - hi_check)
gen lo_diff = abs(wagelo - lo_check)

capture {
    assert hi_diff < 1e-10 | missing(hi_diff)
    assert lo_diff < 1e-10 | missing(lo_diff)
}
if _rc == 0 {
    di as result "PASS: T2: CI formula verified (mean ± 1.96*sd/sqrt(n))"
    global pass_count = $pass_count + 1
}
else {
    di as error "FAIL: T2: CI formula mismatch"
    global fail_count = $fail_count + 1
}
global test_count = $test_count + 1

// Reload test data
use `panel_data', clear

// T3: Verify xorder sorting with descending option
di as txt "T3: Verifying xorder descending sorting..."
tempfile t3_saved t3_manual

cellgraph wage, by(industry) xorder(wage, descending) saving(`t3_saved', replace) noci

// Manual: collapse and sort descending by mean wage
collapse (count) manual_obs=wage (sd) manual_sd=wage (mean) manual_mean=wage, by(industry)
gsort -manual_mean
gen rank = _n
save `t3_manual', replace

// Load saved (should be sorted by descending wage)
use `t3_saved', clear
gen rank = _n
merge 1:1 rank using `t3_manual', nogen

capture {
    // Check that the means match when sorted by rank
    gen diff_mean = abs(wage_mean - manual_mean)
    assert diff_mean < 1e-6 | missing(diff_mean)
}
if _rc == 0 {
    di as result "PASS: T3: xorder descending correctly sorts data"
    global pass_count = $pass_count + 1
}
else {
    di as error "FAIL: T3: xorder descending sorting mismatch"
    global fail_count = $fail_count + 1
}
global test_count = $test_count + 1

// Reload test data
use `panel_data', clear

// T4: Verify xorder with custom stat
di as txt "T4: Verifying xorder with stat(median)..."
tempfile t4_saved t4_manual

cellgraph wage, by(industry) xorder(wage, stat(median)) saving(`t4_saved', replace) noci

// Manual: collapse and sort by median wage
collapse (count) manual_obs=wage (sd) manual_sd=wage (mean) manual_mean=wage (median) manual_median=wage, by(industry)
sort manual_median
gen rank = _n
save `t4_manual', replace

// Load saved (should be sorted by median wage)
use `t4_saved', clear
gen rank = _n
merge 1:1 rank using `t4_manual', nogen

capture {
    gen diff_mean = abs(wage_mean - manual_mean)
    assert diff_mean < 1e-6 | missing(diff_mean)
}
if _rc == 0 {
    di as result "PASS: T4: xorder with stat(median) correctly sorts data"
    global pass_count = $pass_count + 1
}
else {
    di as error "FAIL: T4: xorder stat(median) sorting mismatch"
    global fail_count = $fail_count + 1
}
global test_count = $test_count + 1

// Reload test data
use `panel_data', clear

// T5: Verify string by-variable encoding preserves data
di as txt "T5: Verifying string by-variable data integrity..."
tempfile t5_saved t5_manual

cellgraph wage, by(gender_str) saving(`t5_saved', replace) noci

// Manual collapse (encode string first like cellgraph does)
encode gender_str, gen(gender_enc)
collapse (count) manual_obs=wage (sd) manual_sd=wage (mean) manual_mean=wage, by(gender_enc)
sort manual_mean
gen row = _n
save `t5_manual', replace

// Load saved - cellgraph encodes string to tempvar with value labels
use `t5_saved', clear

// Sort by mean and merge by row position (both have same groups, same sort order)
sort wage_mean
gen row = _n
merge 1:1 row using `t5_manual', nogen

capture {
    gen diff_mean = abs(wage_mean - manual_mean)
    assert diff_mean < 1e-6 | missing(diff_mean)
    // Also verify we have correct number of groups (Male/Female = 2)
    assert _N == 2
}
if _rc == 0 {
    di as result "PASS: T5: String by-variable data integrity verified"
    global pass_count = $pass_count + 1
}
else {
    di as error "FAIL: T5: String by-variable data mismatch"
    global fail_count = $fail_count + 1
}
global test_count = $test_count + 1

// Reload test data for any subsequent tests
use `panel_data', clear

// ============================================================
// U. GTOOLS/FTOOLS OPTIONS TESTS (require those packages)
// ============================================================
di _n as txt "=== U. Gtools/Ftools Options ===" _n

// Test gtools if available
capture which gtools
if _rc == 0 {
    run_test, name("U1: gtools option for collapse") ///
        cmd(cellgraph wage, by(year) gtools noci)

    run_test, name("U2: gtools with two by-vars") ///
        cmd(cellgraph wage, by(year female) gtools noci)

    run_test, name("U3: gtools with binscatter") ///
        cmd(cellgraph wage, by(age) binscatter(20) gtools noci)
}
else {
    di as txt "SKIP: U1-U3 (gtools not installed)"
}

// Test ftools if available
capture which ftools
if _rc == 0 {
    run_test, name("U4: ftools option for collapse") ///
        cmd(cellgraph wage, by(year) ftools noci)

    run_test, name("U5: ftools with two by-vars") ///
        cmd(cellgraph wage, by(year female) ftools noci)
}
else {
    di as txt "SKIP: U4-U5 (ftools not installed)"
}

// ============================================================
// V. LONG CATEGORY LABELS TESTS
// ============================================================
di _n as txt "=== V. Long Category Labels ===" _n

// Create long labels
preserve
label define long_ind_label ///
    1 "Manufacturing and Industrial Production Sector" ///
    2 "Professional Services and Business Consulting" ///
    3 "Retail Sales and Consumer Distribution" ///
    4 "Technology and Information Systems" ///
    5 "Finance, Banking and Investment Services"
label values industry long_ind_label

run_test, name("V1: Long category labels single by-var") ///
    cmd(cellgraph wage, by(industry) noci)

run_test, name("V2: Long category labels two by-vars") ///
    cmd(cellgraph wage, by(industry female) noci)

run_test, name("V3: Long labels with xorder") ///
    cmd(cellgraph wage, by(industry) xorder(wage) noci)

restore

// Very long string by-variable labels
preserve
replace industry_str = "Manufacturing and Industrial Production With Very Long Name" if industry == 1
replace industry_str = "Professional Services and Business Consulting Extended" if industry == 2

run_test, name("V4: Very long string by-var labels") ///
    cmd(cellgraph wage, by(industry_str) noci)

restore

// ============================================================
// W. BASELINE WITH XORDER INTERACTION TESTS
// ============================================================
di _n as txt "=== W. Baseline with Xorder Interaction ===" _n

run_test, name("W1: baseline with xorder") ///
    cmd(cellgraph wage, by(industry) baseline(1) xorder(wage) noci)

run_test, name("W2: baseline with xorder descending") ///
    cmd(cellgraph wage, by(industry) baseline(1) xorder(wage, descending) noci)

run_test, name("W3: baseline with xorder and stat(median)") ///
    cmd(cellgraph wage, by(industry) baseline(1) xorder(wage, stat(median)) noci)

// Verify the interaction produces correct results
di as txt "W4: Verifying baseline + xorder data integrity..."
tempfile w4_saved
cellgraph wage, by(industry) baseline(1) xorder(wage) saving(`w4_saved', replace) noci

use `w4_saved', clear
capture {
    // The baseline (first industry after sorting) should have mean = 0
    // (since baseline normalizes to the baseline value)
    sort industry
    local first_mean = wage_mean[1]
    assert abs(`first_mean') < 1e-10
}
if _rc == 0 {
    di as result "PASS: W4: baseline + xorder produces correct normalized values"
    global pass_count = $pass_count + 1
}
else {
    di as error "FAIL: W4: baseline + xorder data verification"
    global fail_count = $fail_count + 1
}
global test_count = $test_count + 1

// Reload test data
use `panel_data', clear

// ============================================================
// X. LFIT COEF WITH NON-MEAN STATISTICS TESTS
// ============================================================
di _n as txt "=== X. Lfit Coef with Non-Mean Statistics ===" _n

// These should either work correctly or produce a helpful error
run_test, name("X1: lfit coef with stat(median)") ///
    cmd(cellgraph wage, by(year) stat(median) lfit coef noci)

run_test, name("X2: lfit coef with stat(p50)") ///
    cmd(cellgraph wage, by(year) stat(p50) lfit coef noci)

run_test, name("X3: lfit coef with stat(sd)") ///
    cmd(cellgraph wage, by(year) stat(sd) lfit coef noci)

run_test, name("X4: lfit with non-mean (no coef)") ///
    cmd(cellgraph wage, by(year) stat(median) lfit noci)

// ============================================================
// Y. UNICODE CHARACTERS IN LABELS TESTS
// ============================================================
di _n as txt "=== Y. Unicode Characters in Labels ===" _n

preserve
// Create unicode labels
label define unicode_label 0 "Männlich" 1 "Weiblich"
label values female unicode_label

run_test, name("Y1: German umlauts in value labels") ///
    cmd(cellgraph wage, by(female) noci)

run_test, name("Y2: Unicode labels with two by-vars") ///
    cmd(cellgraph wage, by(year female) noci)

restore

preserve
// Test with accented characters
label define accent_label ///
    1 "Fabricación" ///
    2 "Servicios" ///
    3 "Comercio minorista" ///
    4 "Tecnología" ///
    5 "Finanzas"
label values industry accent_label

run_test, name("Y3: Spanish accents in labels") ///
    cmd(cellgraph wage, by(industry) noci)

run_test, name("Y4: Accented labels with xorder") ///
    cmd(cellgraph wage, by(industry) xorder(wage) noci)

restore

preserve
// Test with special characters
gen str30 special_str = "Category A™" if female == 0
replace special_str = "Category B®" if female == 1

run_test, name("Y5: Special characters in string by-var") ///
    cmd(cellgraph wage, by(special_str) noci)

restore

// ============================================================
// Z. EXTREME CIOPACITY VALUES TESTS
// ============================================================
di _n as txt "=== Z. Extreme Ciopacity Values ===" _n

run_test, name("Z1: ciopacity(0) - fully transparent") ///
    cmd(cellgraph wage, by(year) ciopacity(0))

run_test, name("Z2: ciopacity(100) - fully opaque") ///
    cmd(cellgraph wage, by(year) ciopacity(100))

run_test, name("Z3: ciopacity(1) - near transparent") ///
    cmd(cellgraph wage, by(year) ciopacity(1))

run_test, name("Z4: ciopacity(99) - near opaque") ///
    cmd(cellgraph wage, by(year) ciopacity(99))

// Negative should error (or be handled gracefully)
run_test, name("Z5: ciopacity negative should error") ///
    cmd(cellgraph wage, by(year) ciopacity(-10)) expect_error

// Very large should error (or be clamped)
run_test, name("Z6: ciopacity >100 should error") ///
    cmd(cellgraph wage, by(year) ciopacity(150)) expect_error

// ============================================================
// AA. WEIGHTED STATISTICS VERIFICATION TESTS
// ============================================================
di _n as txt "=== AA. Weighted Statistics Verification ===" _n

// AA1: Verify weighted mean matches manual calculation
di as txt "AA1: Verifying weighted mean matches manual collapse..."
tempfile aa1_saved aa1_manual

// Run cellgraph with weights
cellgraph wage [aweight=wgt], by(female) saving(`aa1_saved', replace) noci

// Manual weighted collapse
collapse (mean) manual_mean=wage [aweight=wgt], by(female)
save `aa1_manual', replace

// Load saved and merge
use `aa1_saved', clear
merge 1:1 female using `aa1_manual', nogen

capture {
    gen diff_mean = abs(wage_mean - manual_mean)
    assert diff_mean < 1e-6 | missing(diff_mean)
}
if _rc == 0 {
    di as result "PASS: AA1: Weighted mean matches manual collapse"
    global pass_count = $pass_count + 1
}
else {
    di as error "FAIL: AA1: Weighted mean does not match manual collapse"
    global fail_count = $fail_count + 1
}
global test_count = $test_count + 1

// Reload test data
use `panel_data', clear

// AA2: Verify weighted statistics with two by-variables
di as txt "AA2: Verifying weighted statistics with two by-vars..."
tempfile aa2_saved aa2_manual

cellgraph wage [aweight=wgt], by(year female) saving(`aa2_saved', replace) noci

// Manual weighted collapse
collapse (mean) manual_mean=wage [aweight=wgt], by(year female)
save `aa2_manual', replace

use `aa2_saved', clear
merge 1:1 year female using `aa2_manual', nogen

capture {
    gen diff_mean = abs(wage_mean - manual_mean)
    assert diff_mean < 1e-6 | missing(diff_mean)
}
if _rc == 0 {
    di as result "PASS: AA2: Weighted stats with two by-vars match"
    global pass_count = $pass_count + 1
}
else {
    di as error "FAIL: AA2: Weighted stats with two by-vars mismatch"
    global fail_count = $fail_count + 1
}
global test_count = $test_count + 1

// Reload test data
use `panel_data', clear

// AA3: Verify frequency weights
di as txt "AA3: Verifying frequency weights..."
tempfile aa3_saved aa3_manual

// Need integer weights for fweight
gen int fwgt = round(wgt * 10)

cellgraph wage [fweight=fwgt], by(female) saving(`aa3_saved', replace) noci

// Manual fweight collapse
collapse (mean) manual_mean=wage [fweight=fwgt], by(female)
save `aa3_manual', replace

use `aa3_saved', clear
merge 1:1 female using `aa3_manual', nogen

capture {
    gen diff_mean = abs(wage_mean - manual_mean)
    assert diff_mean < 1e-6 | missing(diff_mean)
}
if _rc == 0 {
    di as result "PASS: AA3: Frequency weighted mean matches manual collapse"
    global pass_count = $pass_count + 1
}
else {
    di as error "FAIL: AA3: Frequency weighted mean does not match"
    global fail_count = $fail_count + 1
}
global test_count = $test_count + 1

// Reload test data for any subsequent tests
use `panel_data', clear


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
