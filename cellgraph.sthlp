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
{help cellgraph##main:Main}
  {cmd:name(}{it:graphname}{cmd:)} {col 26}{...} 
  provide a graph name (just like the name option in other graph commands).
  {cmd:stat(}{it:statistics}{cmd:)} {col 26}{...} 
  the cell statistic to be used. If not specified "mean" is assumed. Other possibilities: min max and sum.
  {cmd:list} {col 26}{...} 
  list collapsed data
  {cmd:options(}{it:string}{cmd:)} {col 26}{...} 
  {cmd:baseline(}{it:string}{cmd:)}: {col 26}{...} 
  normalize series to this baseline observation (subtraction).

{help cellgraph##graphoptions:Graph options}
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
  {cmd:colors(}{it:color1 color2 ...}{cmd:)} {col 26}{...} 
  provide a list of colors to replace standard palette.
  {cmd:lwidth(}{it:string}{cmd:)}: {col 26}{...} 
  specify line width.
  provide any twoway options to pass through to the call of the twoway command
  see the example for why this might be useful. Can also be used to overwrite options that are given as standard,
  for example options(title(My Title)) would overwrite the standard title with "My Title"

{help cellgraph##markeroptions:Marker options}
  {cmd:msymbols(}{it:symbol1 symbol2 ...}{cmd:)} {col 26}{...} 
  Change marker symbol where {it:symbol1 etc} is of {help symbolstyle}.
  {cmd:nomsymbol}: {col 26}{...} 
  do not use marker symbols.
  {cmd:msize(}{it:string}{cmd:)}: {col 26}{...} 
  specify marker size.
  {cmd:mcounts}: {col 26}{...} 
  display observation counts next to markers.

{help cellgraph##binningoptions:Binning options}
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

{help cellgraph##cioptions:Confidence intervals}
  {cmd:noci} {col 26}{...} 
  don't display confidence intervals.
  {cmd:cipattern(}{it:string}{cmd:)}: {col 26}{...} 
  specify confidence interval pattern, either 'shaded' or 'lines'.
  {cmd:ci_shade_coef(}{it:real}{cmd:)}: {col 26}{...} 
  specify the shading coefficient for confidence intervals.

{help cellgraph##legendoptions:Legend}
  {cmd:addnotes}: {col 26}{...} 
  Add notes with sample sizes to the legend.
  {cmd:samplenotes(}{it:string}{cmd:)}: {col 26}{...} 
  add sample notes to the plot.
  {cmd:nonotes} {col 26}{...} 
  don't display any notes in legend.
  {cmd:nodate} {col 26}{...} 
  don't display date in notes.

{help cellgraph##tools:Computational Tools}
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

{marker options}
{title:Options}
{marker main}
{dlgtab:Main}

Main options are:

{marker graphoptions}
{dlgtab:Graph options}

under construction
{marker markeroptions}
{dlgtab:Marker options}

under construction

{marker binningoptions}
{dlgtab:Binning options}

under construction

{marker cioptions}
{dlgtab:Confidence intervals}

under construction

{marker legendoptions}
{dlgtab:Legend}

under construction  

{marker tools}
{dlgtab:Computational Tools}

Options to use the ftools or gtools package for the collapse command. Can result in speed gains for large data sets.


{marker examples}
{title:Examples}

{p 8 16}{inp:. sysuse nlsw88}{p_end}

{p 8 16}{inp:. cellgraph wage, by(grade) }{p_end}

{p 8 16}{inp:. cellgraph wage, by(grade union) }{p_end}

{p 8 16}{inp:. cellgraph wage, by(grade union) stat(max)}{p_end}

{p 8 16}{inp:. cellgraph wage if industry>2 & industry<10, by(grade industry) nonotes noci options(legend(col(2)))) }{p_end}

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
