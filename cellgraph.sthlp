{smcl}
{.-}
help for {cmd:cellgraph} {right:(Johannes F. Schmieder)}
{.-}

 
{title:Title}

{p 4 4 2}{cmd:cellgraph} {hline 2} Command to collapse data to cell level and graph the results.

{title:Table of contents}

{help cellgraph##syntax:Syntax}
{help cellgraph##description:Description}
{help cellgraph##options:Options}
{help cellgraph##examples:Examples}
{help cellgraph##author:Author}
{help cellgraph##also:Also see}

{marker syntax}
{title:Syntax}

{p 8 15 2}
{cmd:cellgraph} {it:varlist} [{help if}] [{help in}] , {cmd:by(}{it:byvar1 byvar2}{cmd:)} [ {cmd:,}
{it:options} ]

{p 4 4 2}where {it:varlist} is a variable or a list of variables. {it:byvar1} and {it:byvar2} are the variables that define the cells. 
The data is collapsed to cell level, where each cell is defined by {it:byvar1} if only one variable is provided or the combination of the values of {it:byvar1} and {it:byvar2} if two variables are provided.

{it:options}{col 26}description
{hline 70}
{ul: Main}
  {cmd:name(}{it:graphname}{cmd:)} {col 26}{...} 
  provide a graph name (just like the name option in other graph commands).
  {cmd:stat(}{it:statistics}{cmd:)} {col 26}{...} 
  the cell statistic to be used. If not specified "mean" is assumed. 
  {col 26}{...} 
  Other possibilities: min, max, sum, sd, var, p10, p25, p50, p75, p90, etc.
  {cmd:list} {col 26}{...} 
  list collapsed data at the end of the command. 
  {cmd:baseline(}{it:string}{cmd:)}: {col 26}{...} 
  normalize series to this baseline observation (subtraction).

{ul:Graph options}
  {cmd:lpattern}: {col 26}{...} 
  specify line pattern.
  {cmd:lpatterns(}{it:string}{cmd:)}: {col 26}{...} 
  specify multiple line patterns.
  {cmd:scatter}: {col 26}{...} 
  create a scatter plot.
  {cmd:line}: {col 26}{...} 
  create a line plot.
  {cmd:gradient}: {col 26}{...} 
  apply a color gradient as the gradient for the second by variable.
  {cmd:colors(}{it:col1 col2 ...}{cmd:)} {col 26}{...} 
  provide a list of colors to replace standard palette.
  {cmd:lwidth(}{it:string}{cmd:)}: {col 26}{...} 
  specify line width.
  {cmd:*} {col 26}{...} 
  provide any twoway options to pass through to the call of the twoway command
  {col 26}{...} 
  see the example for why this might be useful. Can also be used to 
  {col 26}{...} 
  overwrite options that are given as standard, for example {cmd:title(My Title)}
  {col 26}{...} 
  would overwrite the standard title with "My Title"

{ul: Marker options}
  {cmd:msymbols(}{it:symbol1 symbol2 ...}{cmd:)} {col 26}{...} 
  Change marker symbol where {it:symbol1 etc} is of {help symbolstyle}.
  {cmd:nomsymbol}: {col 26}{...} 
  do not use marker symbols.
  {cmd:msize(}{it:string}{cmd:)}: {col 26}{...} 
  specify marker size.
  {cmd:mcounts}: {col 26}{...} 
  display observation counts next to markers.

{ul: Binning options}
  {cmd:binscatter(}{it:integer}{cmd:)}: {col 26}{...} 
  create a binned scatter plot with the specified number of bins.
  {cmd:bin(}{it:real}{cmd:)} {col 26}{...} 
  bin the data by the specified real number as bin width.
  {cmd:lfit}: {col 26}{...} 
  add a linear fit line to the plot.
  {cmd:coef}: {col 26}{...} 
  display regression coefficients.
  {cmd:45deg}: {col 26}{...} 
  add a 45-degree reference line.

{ul: Confidence intervals}
  {cmd:noci} {col 26}{...} 
  don't display confidence intervals.
  {cmd:cipattern(}{it:string}{cmd:)}: {col 26}{...} 
  specify confidence interval pattern, either 'shaded' or 'lines'.
  {cmd:ciopacity(}{it:integer}{cmd:)}: {col 26}{...} 
  specify the opacity for confidence intervals (0-100).

{ul: Legend options}
  {cmd:addnotes}: {col 26}{...} 
  Add notes with sample sizes to the legend.
  {cmd:samplenotes(}{it:string}{cmd:)}: {col 26}{...} 
  add sample notes to the plot.
  {cmd:nonotes} {col 26}{...} 
  don't display any notes in legend.
  {cmd:nodate} {col 26}{...} 
  don't display date in notes.

{ul: Computational Tools}
  {cmd:gtools}: {col 26}{...} 
  use gtools for data processing.
  {cmd:ftools}: {col 26}{...} 
  use ftools for data processing.

{hline 70}

{p}

{marker description}
{title:Description}

{p}

Data is collapsed to cell level, where cells are defined by one or two categorical variables (byvar1 and byvar2) and cell means (or other statistics) of a third variabla ({it:varname}) are graphed.



{marker examples}
{title:Examples}

{space 8}{hline 10} {it:Example 1 - Basic Plot: One outcome variable one by variable} {hline 10}
{cmd}{...}
{* example_start - ex1}{...}
          sysuse nlsw88, clear
          keep if grade>=8
          cellgraph wage, by(grade) 
{* example_end}{...}
{txt}{...}
{space 8}{hline 80}
{space 8}{it:({stata cellgraph_run ex1 using cellgraph.sthlp, preserve:click to run})}

{space 8}{hline 10} {it:Example 2 - One outcome variable, two by variables, marker counts} {hline 10}
{cmd}{...}
{* example_start - ex2}{...}
          sysuse nlsw88, clear
          gen logwage = log(wage) if grade>=8
          label var logwage "Log Wage"
          cellgraph logwage, by(grade union) mcounts
{* example_end}{...}
{txt}{...}
{space 8}{hline 80}
{space 8}{it:({stata cellgraph_run ex2 using cellgraph.sthlp, preserve:click to run})}

{space 8}{hline 10} {it:Example 3 - Multiple Statistics one by variable, color gradient} {hline 10}
{cmd}{...}
{* example_start - ex3}{...}
          sysuse nlsw88, clear
          gen logwage = log(wage) if grade>=8
          label var logwage "Log Wage"
          cellgraph logwage, by(grade) stat(p10 p25 p50 p75 p90) gradient 
{* example_end}{...}
{txt}{...}
{space 8}{hline 80}
{space 8}{it:({stata cellgraph_run ex3 using cellgraph.sthlp,  preserve:click to run})}

{space 8}{hline 10} {it:Example 4 - Two Outcomes, two statistics} {hline 10}
{cmd}{...}
{* example_start - ex4}{...}
          sysuse nlsw88, clear
          cellgraph wage hours if grade>=8 , by(grade) stat (mean median) mcounts ciopacity(20)
{* example_end}{...}
{txt}{...}
{space 8}{hline 80}
{space 8}{it:({stata cellgraph_run ex4 using cellgraph.sthlp,  preserve:click to run})}

{space 8}{hline 10} {it:Example 5 - Binned Scatterplot with Linear Fit} {hline 10}
{cmd}{...}
{* example_start - ex5}{...}
          sysuse auto , clear
          cellgraph mpg, by(weight) binscatter(20) scatter noci lfit coef legend(off)
{* example_end}{...}
{txt}{...}
{space 8}{hline 80}
{space 8}{it:({stata cellgraph_run ex5 using cellgraph.sthlp,  preserve:click to run})}

{space 8}{hline 10} {it:Example 6 - Binned Scatterplot with 2 Groups} {hline 10}
{cmd}{...}
{* example_start - ex6}{...}
          sysuse auto , clear
          cellgraph mpg, by(weight foreign) binscatter(20) scatter noci lfit coef 
{* example_end}{...}
{txt}{...}
{space 8}{hline 80}
{space 8}{it:({stata cellgraph_run ex6 using cellgraph.sthlp,  preserve:click to run})}


{marker author}
{title:Author}

{p}
Johannes F. Schmieder, Boston University, USA

{p}
Email: {browse "mailto:johannes@bu.edu":johannes@bu.edu}

Comments welcome!

{marker also}
{title:Also see}

{p 0 21}
On-line:  help for {help collapse}, {help tabstat}
{p_end}
