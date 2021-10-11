********************************************************************************
*** Main results for Mexican investment data
********************************************************************************
*** Main inputs: MEX_master.dta
*** Additional inputs: 
*** Output: various.png and tables
*** Author: Nicolas Oviedo -
*** Original: 08/20/2021
*** Code: this code generates summary statistics and plots for Mexican data
********************************************************************************
*** Set up
********************************************************************************
cls
query memory
set more off

********************
*User Settings
********************
*User: Andres
*global who = "A" 

*User: Isaac
//global who = "I" 

*User: Nicolas
global who = "N" 

********************************************************************************	
* -------------         Paths and Logs            ------------------------------
********************************************************************************
if "$who" == "N"  {
		global pathinit "D:\Data"
		global sep="/"
}

if "$who" == "N"  {
global output_data "${pathinit}${sep}outputs${sep}microdata${sep}surveys${sep}Mexico"
global figures "$pathinit/figures/Mexico"
global temp "$pathinit/temp"
}

if "$who" == "A"  {
		global pathinit "/Users/jablanco/Dropbox (University of Michigan)/papers_new/LumpyTaxes/Data"
		global sep="/"
}

if "$who" == "A"  {
global output_data "${pathinit}${sep}outputs${sep}microdata${sep}surveys${sep}Mexico"
global figures "$pathinit/figures/Mexico"
global temp "$pathinit/temp"
}

capture log close
log using "${temp}${sep}Mexico_step3.txt", append
cd "$output_data"

********************************************************************************	
*** Summary statistics
********************************************************************************
use MEX_master.dta, clear

estpost tabstat id year labor wage_bill sales capital_f inv_total,  statistics(count mean sd min max) columns(statistics)
esttab . using Mexico_summary.tex, cells("count mean sd min max") nonum noobs label replace

********************************************************************************	
*** Main plots
********************************************************************************
gen plants = 1
collapse(sum) labor wage_bill sales capital_f inv_total plants, by(year)

lab var labor "Labor"
lab var wage_bill "Wages"
lab var sales "Sales"
lab var capital_f "Total capital stock"
lab var inv_total "Investment"
lab var plants "Number of plants"

local varlist "labor wage_bill sales capital_f inv_total"
local colores "olive navy maroon teal cyan orange"
forvalues t = 1/5{
	 local color = word("`colores'", `t')
	 local var = word("`varlist'", `t')
	 #delim;
	 twoway bar plants year,
	 color(`color') yaxis(1) ||
	 line `var' year, 
	 yaxis(2) legend(size(vsmall))
	 name(`var', replace);
	 #delim cr
	 gr export "${figures}${sep}MEX_`var'.png", replace
}