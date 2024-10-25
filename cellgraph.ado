// Author: Johannes F. Schmieder
// Department of Economics, Boston University
// cellgraph.ado
// Version 2019.08.26

// First Version: April 2008
// Comments and suggestions welcome: johannes{at}bu.edu

// Notes:
// Routine to generate variably by variable graph (similar to tabstat but as graph)

// Usage:
// cellgraph graphvars, by(byvar1 byvar2) [options]

// Data is collapsed to cell level, where cells are defined by one or two categorical variables (byvar1 and byvar2)
// and cell means (or other statistics) of a third variable (graphvar) are graphed. If more than one graphvar is specified,
// then each graphvar is plotted.
//
// Options:
// colors(color1 color2 ...) : provide a list of colors to replace standard palette
// name(graphname) : provide a graph name (just like the name option in other graph commands)
// stat(statistics) : the cell statistic to be used if not specified "mean" is assumed,
// other possibilities: min max and sum, ...
// it is also possible to show more than one stat
// noci : don't display confidence intervals
// nonotes : don't display any notes in legend
// nodate: don't display date in notes
// *: provide any twoway options to pass through to the call of the twoway command
//   see the example for why this might be useful. Can also used to overwrite options that are given as standard,
//   for example title(My Title) would overwrite the standard title with "My Title"


// Example:
/*
	   sysuse nlsw88
	   cellgraph wage, by(grade)
	   cellgraph wage, by(grade union)
	   cellgraph wage, by(grade union)  stat(max)
	   cellgraph wage if industry>2 & industry<10, by(grade industry) nonotes noci legend(col(2))
	   cellgraph wage, by(grade) stat(p25 p50 p90)
	   cellgraph wage, by(grade) stat(sd iqr)
	   cellgraph wage married, by(grade)
	   cellgraph wage married, by(grade) stat(sd iqr)

*/

version 14.1
capture program drop cellgraph
program define cellgraph
	syntax varlist [if] [in] [aweight fweight] , by(str) ///
		[ ///
		Stat(str) ///
		bin(real 0) ///
		scatter ///
		line ///
		lfit ///
		coef ///
		45deg ///
		GRADient ///
		binscatter(integer 0) ///
		BASEline(str) /// Normalize series to this baseline observation (subtraction)
		Colors(str) ///
		lpattern ///
		lpatterns(str) /// 		
		Name(str) ///
		Title(str) SUBTitle(passthru) YTITle(passthru)  ///
		NOCI ADDNOTES NODATE NOTITLE NONOTES ///
		msymbol(passthru) ///
		msymbols(str) ///
		NOMSYMbol /// 
		MSIZE(passthru) ///
		LIst SAMPLENotes(str) ///
		gtools ftools ///
		mcounts /// Option to display observation counts next to markers
		lwidth(passthru) ///
		* ///
	]


	local colors `colors' ///
		dknavy  cranberry dkgreen edkblue ///
		dkorange maroon olive 	eltblue ///
		eltgreen emidblue erose blue ///
		purple brown cyan  ebblue ///
		emerald orange forest_green gold  ///
		green khaki lavender lime ///
		ltblue ltbluishgray ltkhaki  ///
		midblue midgreen mint navy  olive_teal magenta ///
		orange orange_red pink red sand sandb sienna stone teal yellow

	// https://pinetools.com/gradient-generator

	if "`lpattern'"=="lpattern" {
		local lpattern_dum = 1
	}
	else local lpattern_dum = 0
	
	local lpatterns `lpatterns' ///
		solid dash longdash shortdash dash_dot  shortdash_dot  longdash_dot dot

	if "`nomsymbol'"=="" {
		local msymbol_dum = 1
	}
	else local msymbol_dum = 0

	local msymbols `msymbols' ///
		square circle diamond triangle circle_hollow diamond_hollow triangle_hollow square_hollow

	marksample touse

	// if "`msymbol'"=="" local msymbol msymbol("O")
	// if "`msymbol'"=="" local msymbol msymbol(none)

	local wc : word count `by'
	if `wc'>2 {
		disp "Specify maximum 2 by variables"
		error 198
	}
	else if `wc'==2 {
		tokenize `by'
		confirm variable `1'
		confirm variable `2'
		qui tab `2' if `touse' & `2'<.
		local N_unique = r(r)
		local steps = `N_unique'
		cap assert r(r) <= 60
		if _rc {
			disp in red "Second By-Variable may only take 60 or less distinct values"
			error 198
		}
	}
	else {
		confirm variable `by'
	}

	if "`gradient'"!="" {
		local color1 26 31 191
		local r1 : word 1 of `color1'
		local g1 : word 2 of `color1'
		local b1 : word 3 of `color1'

		local color2 234 36 35
		local r2 : word 1 of `color2'
		local g2 : word 2 of `color2'
		local b2 : word 3 of `color2'

		if `"`steps'"'=="" local steps 26

		local colors
		forval i = 1/`steps' {
			local r = round(`r1' + (`i'/`steps') * (`r2'-`r1'))
			local g = round(`g1' + (`i'/`steps') * (`g2'-`g1'))
			local b = round(`b1' + (`i'/`steps') * (`b2'-`b1'))
			if `i'==1 local colors `r' `g' `b'
			else      local colors `colors'; `r' `g' `b'
		}

		locallist `colors', name(colors)
	}



	if "`stat'"=="" local stat mean
	if "`stat'"!="mean" local noci noci
	local sc : word count `stat'
	if `sc'>1 local noci noci

	if `sc'>1 & `wc'>1 {
		di in red "You can either specify more than 1 'by' variable or more than one statistic, but not both"
		error 198
	}

	local figtitle `"`title'"'

	local vc : word count `varlist'
	local i 1
	foreach v in `varlist' {
		local varlabel : variable label `v'
		if `"`varlabel'"'==`""' local varlabel `"`v'"'
		local title`i++' `"`varlabel'"'
	}
	if "`title'"=="" local title `varlist'
	if "`name'"!="" local nameopt name(`name')

	preserve
	qui keep if `touse'
	if `wc'==1 & `vc'==1 {
		qui count if `varlist'!=. & `by' !=. & `touse'
		local N = r(N)
		local cattit : variable label `by'
		if "`cattit'"=="" local cattit `by'
	}
	if `wc'==1 & `vc'>1 {
		local cattit : variable label `by'
		if "`cattit'"=="" local cattit `by'
	}

	local clist
	foreach v in `varlist' {
		local clist `clist' (count) obs`v'=`v' (sd) sd`v'=`v'
		foreach s in `stat' {
			if "`s'"!="var"	local clist `clist' (`s') `v'_`s'=`v'
			else {
				local clist `clist' (sd) `v'_`s'=`v'
			}
		}
	}

	if `bin'!=0 & `binscatter'!=0 {
		di in red "Options 'bin' and 'binscatter'"
		error 184 // cannot be combined
	}
	if `wc'==1  & `bin'!=0 {
		replace `by' = `by'-mod(`by',`bin')+`bin'*0.5
	}
	if `wc'==2  & `bin'!=0 {
		local first_by_var : word 1 of `by'
		replace `first_by_var' = `first_by_var'-mod(`first_by_var',`bin')+`bin'*0.5
	}
	if `wc'==1 & `binscatter'!=0 {
		local first_by_var : word 1 of `by'
		tempvar miss dum binned
		g `miss' = missing(`first_by_var')
		bys `miss' (`first_by_var'): gen `dum' = int(`binscatter'*(_n-1)/_N)+1
		egen `binned' = mean(`first_by_var'), by(`dum')
		qui replace `first_by_var' = `binned'
	}
	if `wc'==2 & `binscatter'!=0 {
		local first_by_var : word 1 of `by'
		tempvar miss dum binned
		g `miss' = missing(`first_by_var')
		bys `miss' `2' (`first_by_var'): gen `dum' = int(`binscatter'*(_n-1)/_N)+1
		egen `binned' = mean(`first_by_var'), by(`dum' `2')
		qui replace `first_by_var' = `binned'
	}




	if "`gtools'"=="gtools" gcollapse  `clist' if `touse' [`weight' `exp'], by(`by') fast
	else if "`ftools'"=="ftools" fcollapse  `clist' if `touse' [`weight' `exp'], by(`by') fast
	else qui collapse  `clist' if `touse' [`weight' `exp'], by(`by') fast

	foreach s in `stat' {
		local j 1
		foreach v in `varlist' {
			if "`s'"=="var"	{
				replace `v'_`s' = `v'_`s'^2
				label var `v'_`s' "Variance of `title`j++''"
			}
			if "`s'"=="mean" {
				g `v'hi = `v'_mean + 1.96*sd`v'/sqrt(obs`v')
				g `v'lo = `v'_mean - 1.96*sd`v'/sqrt(obs`v')
				label var `v'_`s' "`title`j++''"
			}
			else {
				__statlabel `s'
				label var `v'_`s' "`__statlabel' of `title`j++''"
				// label var `v'_`s' "`title`j++''"
			}
		}
	}

	// Renormalize Variables to Baseline
	if `"`baseline'"'!=`""' & `wc'==1 {
		foreach s in `stat' {
			foreach v in `varlist' {
				qui sum  `v'_`s' if  `by'==`baseline'
				replace `v'_`s' = `v'_`s' - r(mean)
				if "`s'"=="mean" {
					replace `v'hi = `v'_`s' - r(mean)
					replace `v'lo = `v'_`s' - r(mean)
				}
			}
		}
	}
	if `"`baseline'"'!=`""' & `wc'==2 {
		foreach s in `stat' {
			foreach v in `varlist' {
				qui tab `2', gen(__dby2_)
				forvalues i =1/`N_unique' {
					qui sum  `v'_`s' if __dby2_`i'==1 & `1'==`baseline'
					replace `v'_`s' = `v'_`s' - r(mean) if __dby2_`i'==1
					if "`s'"=="mean" {
						replace `v'hi = `v'_`s' - r(mean) if __dby2_`i'==1
						replace `v'lo = `v'_`s' - r(mean) if __dby2_`i'==1
					}
				}
				drop __dby2_*
			}
		}
	}



	local varcount 0
	foreach v in `varlist' {
		label var obs`v' "No. Observations"
		local varcount = `varcount'+1
	}

	if `varcount'==1 {
		if `"`ytitle'"'=="" local ytitle ytitle(`"`title1'"')
	}

	local graphcmd connected
	if "`scatter'"!="" local graphcmd scatter
	if "`line'"!="" local graphcmd line

	if `wc'==1 {
		local notes ""Number of observations: `N'" "
		if  "`stat'"=="mean" & "`noci'"=="" {
			local i 1
			foreach v in `varlist' {
				gettoken col colors:colors
				
				if `msymbol_dum' {
					gettoken msym msymbols:msymbols
					local msymbol msymbol(`msym')
				}
				else local msymbol msymbol(none)
				

				if `lpattern_dum' {
					gettoken lpat lpatterns:lpatterns
					// 					local lpattern lpattern(`"`lpat'"') 
					local lpattern lpattern(`"`lpat'"') 
				}
				else {
					local lpattern lpattern("#")
				}

				if "`mcounts'"!=""{
					local mlabel mlabel(obs`v') mlabcolor(black) mlabsize(vsmall) mlabposition(1)
				}

				local graphs 	`graphs'	(`graphcmd' `v'hi `by', lpattern("#") color("`col'") msymbol(none) )  ///
					(`graphcmd' `v'lo `by' , lpattern("#") color("`col'") msymbol(none) )
				if "`lfit'"=="lfit" {
					if `varcount'==1 & `sc'==1 local lfit_col maroon
					else local lfit_col `col'
					local graphs 	`graphs'	(lfit `v'_mean `by' , lpattern("shortdash") color(`lfit_col') )
				}
				local graphs `graphs' (`graphcmd' `v'_mean `by' , `lpattern' `msymbol' `msize' `mlabel' `lwidth' color("`col'") )

				if "`lfit'"=="lfit" local order `order' `=`i'*4'
				else local order `order' `=`i++'*3'

				if "`coef'"=="coef" {
					reg `v'_mean `by'
					__localfmt coef_b = _b[`by'], digits(a2)
					__localfmt coef_se = _se[`by'], digits(a2)
					sum `v'_mean
					local ymin = r(min)
					local ymax = r(max)
					sum `by'
					local xmin = r(min)
					local xmax = r(max)
				}
			}
			if "`45deg'"=="45deg" {
				local graphs `graphs' (line `by' `by' , lpattern("-") color(gray) )
			}
		}
		if  "`stat'"!="mean" | "`noci'"!="" {
			local i 1
			foreach s in `stat' {
				foreach v in `varlist' {
					gettoken col colors:colors
				if `msymbol_dum' {
					gettoken msym msymbols:msymbols
					local msymbol msymbol(`msym')
				}
				else local msymbol msymbol(none)

					if `lpattern_dum'  {
						gettoken lpat lpatterns:lpatterns
						// 					local lpattern lpattern(`"`lpat'"') 
						local lpattern lpattern(`"`lpat'"') 
					}
					else {
						local lpattern lpattern("#")
					}

					if "`lfit'"=="lfit" {
						if `varcount'==1 & `sc'==1 local lfit_col maroon
						else local lfit_col `col'
						local graphs 	`graphs'	(lfit `v'_mean `by' , lpattern("shortdash") color(`lfit_col') )
					}
					if "`mcounts'"!=""{
						local mlabel mlabel(obs`v') mlabcolor(black) mlabsize(vsmall) mlabposition(1)
					}

					local graphs `graphs' (`graphcmd' `v'_`s' `by' , `lpattern' `msymbol' `msize' `mlabel' `lwidth' color("`col'") )
					// local statlabel : variable label `v'_`s'
					// local legendlabel `legendlabel' label(`i' "`s'")
					if "`lfit'"=="lfit" local order `order' `=`i'*2'
					else local order `order' `=`i++'*1'

					if "`coef'"=="coef" {
						reg `v'_`s' `by'
						__localfmt coef_b = _b[`by'], digits(a2)
						__localfmt coef_se = _se[`by'], digits(a2)
						sum `v'_`s'
						local ymin = r(min)
						local ymax = r(max)
						sum `by'
						local xmin = r(min)
						local xmax = r(max)
					}
				}
			}
			if "`45deg'"=="45deg" {
				local graphs `graphs' (line `by' `by' , lpattern("-") color(gray) )
			}
		}
	}
	// di `"`order'"'


	if `wc'==2 { // go over categories of second by variable
		foreach v in `varlist' {
			local cattit : variable label `1'
			if "`cattit'"=="" local cattit `1'
			// Count observations in by groups:
			tempvar N
			g `N' = .
			bys `2' `1': replace `N' = sum(obs`v')

			qui tab `2', gen(__dby2_)
			local coef_offset 0
			forvalues i =1/`N_unique' {

				local catlabel : variable label __dby2_`i'
				local catlabel = subinstr("`catlabel'","`2'==","",.)
				qui sum `N' if __dby2_`i'==1
				local max = r(max)
				local notes "`notes' "Number of obs, `catlabel':    `max'""

				gettoken col colors:colors
				if `msymbol_dum' {
					gettoken msym msymbols:msymbols
					local msymbol msymbol(`msym')
				}
				else local msymbol msymbol(none)
				if "`mcounts'"!=""{
					local mlabel mlabel(obs`v') mlabcolor(black) mlabsize(vsmall) mlabposition(1)
				}
				if `lpattern_dum'  {
					gettoken lpat lpatterns:lpatterns
					// 					local lpattern lpattern(`"`lpat'"') 
					local lpattern lpattern(`"`lpat'"') 
				}
				else {
					local lpattern lpattern("#")
				}

				if "`noci'"!="" {
					if "`lfit'"=="lfit" {
						local graphs 	`graphs'	(lfit `v'_`stat'   `1' if __dby2_`i'==1, lpattern("shortdash") color("`col'") )
					}

					local graphs `graphs' ///
						(`graphcmd' `v'_`stat'   `1' if __dby2_`i'==1 ,  `lpattern' `msymbol' `msize' `mlabel' `lwidth' color("`col'") )

					if "`lfit'"=="lfit" {
						local legendlabel `legendlabel' label(`=`i'*2' "`catlabel'")
						local order `order' `=`i'*2'
					}
					else {
						local order `order' `i'
						local legendlabel `legendlabel' label(`i' "`catlabel'")
					}
				}
				else {
					local graphs `graphs' ///
						(`graphcmd' `v'hi `1' if __dby2_`i'==1  , lpattern("#") color(`col'*.6) msymbol(none) )  ///
						(`graphcmd' `v'lo `1' if __dby2_`i'==1  , lpattern("#") color(`col'*.6) msymbol(none) )  ///
						(`graphcmd' `v'_`stat'  `1' if __dby2_`i'==1 , `lpattern' `msymbol' `msize' `mlabel' `lwidth' color("`col'") )
					local legendlabel `legendlabel' label(`=`i'*3' "`catlabel'")
					local order `order' `=`i'*3'
				}
				if "`coef'"=="coef" {
					reg `v'_`stat' `1' if __dby2_`i'==1
					__localfmt coef_b = _b[`1'], digits(a2)
					__localfmt coef_se = _se[`1'], digits(a2)
					sum `v'_`stat' // if __dby2_`i'==1
					local ymin = r(min)
					local ymax = r(max)
					sum `1'
					local xmin = r(min)
					local xmax = r(max)
					local xpos = `xmin' + 0.85 * (`xmax' - `xmin')
					if `coef_b' >0  local ypos =  `ymin' + (0.075 * `i') * (`ymax' - `ymin')
					if `coef_b' <0  local ypos =  `ymin' + (0.95 - (0.075 * `i')) * (`ymax' - `ymin')
					local txt `txt' text(`ypos' `xpos' "Slope: `coef_b' [`coef_se']", color("`col'"))
				}
			}
		}
		if "`45deg'"=="45deg" {
			local graphs `graphs' (line `1' `1' , lpattern("-") color(gray) )
		}
	}

	// local N_legend_items: word count `order'
	// if `N_legend_items' > 1 local legcol legend(col(2))

	if "`addnotes'"=="addnotes" {
		if "`noci'"=="" local notes "`notes' "Bands are 95% confidence intervals""
		if "`nodate'"=="" local notes "`notes' "`c(current_date)' at `c(current_time)'" "		
	} 
	else {
		local notes
	}
	if "`samplenotes'"!=""  local notes "`notes' "`samplenotes'" "
	/* if "`nonotes'"=="nonotes" local notes */
	// 	if "`legendlabel'"!="" local legendlabel legend(`legendlabel')

	sort `by'
	if `"`figtitle'"'==`""' {
		if `sc'==1 {
			local figtitle `"`=proper("`stat'")' `title1' by `cattit'"'
		}
		else {
			local figtitle `"`title1' by `cattit'"'
		}
	}
	if `"`coef'"'=="coef" & `wc'==1 {
		// local figtitle `"`figtitle', Slope: `coef_b' [`coef_se'] "'

		local xpos = `xmin' + 0.85 * (`xmax' - `xmin')
		if `coef_b' >0  local ypos =  `ymin' + 0.1 * (`ymax' - `ymin')
		if `coef_b' <0  local ypos =  `ymin' + 0.85 * (`ymax' - `ymin')
		local txt text(`ypos' `xpos' "Slope: `coef_b' [`coef_se'] ")
	}

	if `"`notitle'"'=="notitle" local figtitle ""



	// if `"`subtitle'"' != "" {
	// 	local subtitle subtitle(`"`subtitle'"', margin(small) size(small) )
	// }
	twoway  ///
		`graphs' ///
		, scheme(s2mono) ///
		title(`"`figtitle'"', margin(small) size(small) ) /// box bexpand
		`subtitle' ///
		legend(order(`order') ring(1) region(color(none) margin(zero)) ///
		size(small) symysize(*.5) symxsize(*1.2) ///
		`legendlabel') ///
		legend(note(`notes' , ///
		size(vsmall) pos(4) ring(1) justification(right) xoffset(0))) ///
		xtitle(`"`cattit'"') xlabel(`xla', labsize(medsmall)) ylabel(,labsize(medsmall)) ///
		ysize(7.5) xsize(10) graphr(color(white)) `nameopt' `options' ///
		`ytitle' `txt'

	if "`list'"!="" {
		list `by' *`v'*  , clean noo div //  sum(obs`v') noo div
		save ./export_cellgraph.dta, replace
	}
	restore

end


cap program drop __statlabel
program define __statlabel
	local stat `0'
	if "`stat'"=="sd"  local __statlabel "SD"
	if "`stat'"=="iqr" local __statlabel "Interquartile Range"
	if "`stat'"=="median" local __statlabel "Median"
	if "`stat'"=="count" local __statlabel "Count"

	forval i = 1/99 {
		if "`stat'"=="p`i'" {
			if mod(`i',10)==1 local pfx st
			else if mod(`i',10)==2 local pfx nd
			else if mod(`i',10)==3 local pfx rd
			else local pfx th
			if inlist(`i',11,12,13) local pfx th
			local __statlabel "`i'`pfx' pct"
		}
	}

	if "`__statlabel'"=="" local __statlabel "`stat'"
	c_local __statlabel `"`__statlabel'"'
end // __statlabel

/*-------------------------------------------------------*/
/* Tool to calculate expression, format and save in local  */
/*-------------------------------------------------------*/
cap program drop __localfmt
program define __localfmt
	syntax name =exp, digits(str)  // fmt = a2

	__SignificantDigits `digits' ``exp''
	local formatted_local : disp `fmt' ``exp''
	c_local `namelist' `formatted_local'

end // __localfmt

/*-------------------------------------------------------*/
/* Tool to calculate expression, format and save in local  */
/*-------------------------------------------------------*/
cap program drop __SignificantDigits
program define __SignificantDigits // idea stolen from outreg2.ado
	args fmt value
	local d = substr("`fmt'", 2, .)
	capt confirm integer number `d'
	if _rc {
		di as err `"`fmt' not allowed"'
		exit 198
	}
	// missing: format does not matter
	if `value'>=. local fmt "%9.0g"
	// integer: print no decimal places
	else if (`value'-int(`value'))==0 {
		local fmt "%12.0f"
	}
	// value in (-1,1): display up to 9 decimal places with d significant
	// digits, then switch to e-format with d-1 decimal places
	else if abs(`value')<1 {
		local right = -int(log10(abs(`value'-int(`value')))) // zeros after dp
		local dec = max(1,`d' + `right')
		if `dec'<=9 {
			local fmt "%12.`dec'f"
		}
		else {
			local fmt "%12.`=min(9,`d'-1)'e"
		}
	}
	// |values|>=1: display d+1 significant digits or more with at least one
	// decimal place and up to nine digits before the decimal point, then
	// switch to e-format
	else {
		local left = int(log10(abs(`value'))+1) // digits before dp
		if `left'<=9 {
			local fmt "%12.`=max(1,`d' - `left' + 1)'f"
		}
		else {
			local fmt "%12.0e" // alternatively: "%12.`=min(9,`d'-1)'e"
		}
	}
	c_local fmt "`fmt'"
end


// sysuse auto , clear
// cellgraph price, by(gear_ratio foreign) msymbols(triangle diamond)
