// ================================================	
// ===== Code to test cellgraph.ado =====
// ================================================
clear all
set seed 12345
program drop _all
graph drop _all

do cellgraph.ado



// ====== Create Test Data ======

set obs 1000 
// Set up the base number of individuals and time period
local N = 1000
local tmin = 2000
local tmax = 2020

// Create an unbalanced panel by randomly dropping some observations
local rows = `N' * (`tmax' - `tmin' + 1)
set obs `rows'

// Generate person and year identifiers
gen person_id = ceil(_n/(`tmax' - `tmin' + 1))
bysort person_id: gen year = `tmin' + _n - 1

// Randomly drop some observations to create unbalanced panel (about 20%)
gen random = runiform()
drop if random < 0.2

// Generate time-invariant characteristics
by person_id: gen female = runiform() < 0.45 if _n == 1
by person_id: replace female = female[1] if _n > 1

// Generate age (starting between 25-45 in 2000)
by person_id: gen age = ceil(runiform() * 20 + 25) if year == 2000
by person_id: replace age = age[_n-1] + 1 if _n > 1

// Generate education (between 12-20 years, time-invariant)
by person_id: gen educ = ceil(runiform() * 8 + 12) if _n == 1
by person_id: replace educ = educ[1] if _n > 1

// Generate industry (1-5, allowing for some job changes)
by person_id: gen industry = ceil(runiform() * 5) if _n == 1
by person_id: replace industry = industry[_n-1] if _n > 1
replace industry = ceil(runiform() * 5) if runiform() < 0.1  // 10% chance of industry change

// Generate log wage with returns to education, experience, and gender gap
gen experience = age - educ - 6
gen logwage = 1.5 + 0.08 * educ + 0.02 * experience - 0.0003 * experience^2 ///
    - 0.15 * female + 0.1 * industry + rnormal(0, 0.3) * (year-`tmin')*.03

// Label variables
label var person_id "Person identifier"
label var year "Year"
label var age "Age in years"
label var educ "Years of education"
label var logwage "Log hourly wage"
label var female "Female (0/1)"
label var industry "Industry (1-5)"
label var experience "Years of potential experience"

// Label values for industry
label define ind_label 1 "Manufacturing" 2 "Services" 3 "Retail" 4 "Technology" 5 "Finance"
label values industry ind_label

label define female_label 0 "Male" 1 "Female"
label values female female_label

// Sort dataset
sort person_id year

// Display summary statistics
summarize

// ====== Test Cellgraph ======

set trace on  
set tracedepth 1

local i 100 

cellgraph logwage, by(year) name(g`i++') title("Log Wage") shaded_ci


exit 

cellgraph logwage, by(year) name(g`i++') title("Log Wage") mcounts addnotes

cellgraph logwage, by(year female) name(g`i++') title("Log Wage") mcounts 

cellgraph logwage, by(year) name(g`i++') title("Log Wage") xline(0) stat(p10 p50 p90) ///
	legend(size(vsmall)) ylabel(,angle(horizontal)) ///
	yscale(range(2.7 4)) ylabel(2.7(.1)4) msymbol(none) lpattern 

exit 

cellgraph logwage, by(year) name(g`i++') title("Log Wage") ///
	xline(0) mcounts stat(p10 p50 p90) legend(size(vsmall)) addnotes ylabel(,angle(horizontal)) ///
	yscale(range(0 12)) ylabel(0(1)12) msymbol(none) lpattern
//
// 	err
// cellgraph logearn, by(yrsince) name(g`i++') title("Log Earnings") ///
// 	xline(0) mcounts stat(p10 p50 p90) legend(size(small) pos(10) ring(0) col(1))  msymbol(none) lpattern
	
cellgraph logwage, by(year) name(g`i++') title("Log Earnings") ///
	xline(0)   legend(size(small) pos(10) ring(0) col(1))  msymbol(none) 

cellgraph logwage, by(year treatment) msymbol(none)
err
	
cellgraph logwage, by(year treatment) name(g`i++') title("Log Earnings") ///
	xline(0) mcounts  legend(size(small) pos(10) ring(0) col(1))  msymbol(none) lpattern
err

local i 100
qui sum logwage 
replace logwage = logwage - r(mean)
cellgraph logwage, by(year) name(g`i++') title("Log Earnings") xline(0) mcounts 

err
cellgraph logearn, by(yrsince treatment) name(g`i++') title("Log Earnings") xline(0) mcounts
cellgraph logearn firmeff, by(yrsince) name(g`i++') title("Log Earnings") xline(0) mcounts legend(col(1))
cellgraph logearn, by(yrsince treatment) name(g`i++') stat(median) title("Log Earnings") xline(0) mcounts

cellgraph logearn if treatment==1, by(yrsince ) name(g`i++') stat(p25 median p75) title("Log Earnings") xline(0) mcounts 

// cellgraph logwage logwage2, by(year) stat(mean) name(g`i++')

// cellgraph logwage, by(year treatment) stat(mean) name(g`i++')

// set trace on
// set tracedepth 1
// cellgraph logwage, by(year) stat(p10 p25 p50 p75 p90) name(g`i++') nonotes legend(col(2))

// this produces a graph equivalent to the popular binscatter command
// cellgraph logwage, by(ability) binscatter(20) lfit scatter nonotes legend(off)

sysuse nlsw88, clear 
cellgraph wage, by(grade union) mcounts 
cellgraph wage, by(grade union) mcounts stat(count)
