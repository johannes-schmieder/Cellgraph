// ================================================	
// ===== Code to test cellgraph.ado =====
// ================================================
clear all
set seed 12345
program drop _all
graph drop _all

do cellgraph.ado
 
set trace on
set tracedepth 1


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
gen logwage = 1.5 + 0.08 * educ + 0.12 * experience - 0.002 * experience^2 ///
    - 0.15 * female + 0.1 * industry + rnormal(0, 0.3) * (year-`tmin')*.03

	
g byear = year - age 

// Label variables
label var person_id "Person identifier"
label var year "Year"
label var age "Age in years"
label var educ "Years of education"
label var logwage "Log hourly wage"
label var female "Female (0/1)"
label var industry "Industry (1-5)"
label var experience "Years of potential experience"
label var byear "Birth Year"

// Label values for industry
label define ind_label 1 "Manufacturing" 2 "Services" 3 "Retail" 4 "Technology" 5 "Finance"
label values industry ind_label

label define female_label 0 "Male" 1 "Female"
label values female female_label

// Sort dataset
sort person_id year


// ====== Test Cellgraph ======

set trace on  
set tracedepth 1

local i 100 

cellgraph educ industry, by(year)



cellgraph logwage , by(year female) name(g`i++') title("Log Wage") ///
	cipattern("shaded") lpattern ciopacity(10) nomsymbol

cellgraph logwage, by(year) name(g`i++') title("Log Wage") cipattern("lines") lpattern 



cellgraph logwage, by(year) name(g`i++') title("Log Wage") mcounts addnotes

cellgraph logwage, by(year female) name(g`i++') title("Log Wage") mcounts 

cellgraph logwage, by(year female) name(g`i++') title("Log Wage") mcounts colors(128 0 128; 128 128 0)

cellgraph logwage, by(year) name(g`i++') title("Log Wage") xline(0) stat(p10 p50 p90) ///
	legend(size(vsmall)) ylabel(,angle(horizontal)) ///
	yscale(range(2.7 4)) ylabel(3.5(.5)6) nomsymbol lpattern 


cellgraph logwage, by(year) name(g`i++') title("Log Wage") ///
	xline(0) mcounts stat(p10 p50 p90) legend(size(vsmall)) addnotes ylabel(,angle(horizontal)) ///
	nomsymbol lpattern gradient
	
cellgraph logwage, by(year) name(g`i++') title("Log Earnings") ///
	xline(0)   legend(size(small) pos(10) ring(0) col(1))  line  cipattern(shaded)



cellgraph logwage, by(year byear) gradient line  legend(off) noci

cellgraph logwage if age<=50 & byear>=1970, by(year byear) gradient line  legend(off) noci ///
	title(Wage - experience profiles for different birth cohorts)

