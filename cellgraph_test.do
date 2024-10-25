// This is a comment at the top.

cd  "/Users/johannes/Google Drive/Ado/"
clear
program drop _all
graph drop _all

do cellgraph.ado

use test_data_os, clear 
set trace on  
set tracedepth 1
g logearn2 = logearn 
local i 100 
cellgraph logearn, by(yrsince) name(g`i++') title("Log Earnings") ///
	xline(0) mcounts stat(p10 p50 p90) legend(size(vsmall)) addnotes ylabel(,angle(horizontal)) ///
	yscale(range(0 12)) ylabel(0(1)12) msymbol(none) lpattern
//
// 	err
// cellgraph logearn, by(yrsince) name(g`i++') title("Log Earnings") ///
// 	xline(0) mcounts stat(p10 p50 p90) legend(size(small) pos(10) ring(0) col(1))  msymbol(none) lpattern
	
cellgraph logearn, by(yrsince ) name(g`i++') title("Log Earnings") ///
	xline(0)   legend(size(small) pos(10) ring(0) col(1))  msymbol(none) 

cellgraph logearn, by(yrsince treatment) msymbol(none)
err
	
cellgraph logearn, by(yrsince treatment) name(g`i++') title("Log Earnings") ///
	xline(0) mcounts  legend(size(small) pos(10) ring(0) col(1))  msymbol(none) lpattern
err

local i 100
qui sum logearn 
replace logearn = logearn - r(mean)
cellgraph logearn, by(yrsince) name(g`i++') title("Log Earnings") xline(0) mcounts 

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
