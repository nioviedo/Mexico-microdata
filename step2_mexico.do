********************************************************************************
*** Mexican investment data: clean and append to master
********************************************************************************
*** Main inputs: mex84output.dta-mex90output.dta
*** Additional inputs: 
*** Output: MEX_master
*** Author: Utsav Bhadra
*** Notes: edited by Nicolas Oviedo - 06/14/2021
********************************************************************************
*** Set up
********************************************************************************
cls
drop _all
query memory
set more off
********************
*User Settings
********************
*User: andres
//global who = "A" 

*User: Isaac
//global who = "I"

*User: Nicolas
global who = "N" 

*User: Ustav
//global who = "U"

********************************************************************************	
*** Paths and Logs            
********************************************************************************
if "$who" == "A"  global pathinit "/Users/jablanco/Dropbox (University of Michigan)/papers_new/LumpyTaxes"
if "$who" == "N"  global pathinit "D:"
if "$who" == "U"  global pathinit "/Users/utsavbhadra/Desktop/UMich/Academics/Summer 2021/SRA/My stuff/Mexico"

if "$who" ~= "U" {
	global output_data "$pathinit/Data/outputs/microdata/surveys/Mexico"
	global input_data  "$pathinit/Data/inputs/microdata/survey/Mexico/data files"
	global temp_file   "$pathinit/Data/Temp"
	global provisional "$pathinit/Data/outputs/microdata/surveys/Mexico/provisional"
	*global figures    "$pathinit/Data/figures/mexico"
	cap log close
	log using "$temp_file/step2mexico.log", append
}

if "$who" == "U" {
	global output_data "$pathinit"
	global provisional "/Users/utsavbhadra/Desktop"
}

cd "$output_data"

********************************************************************************	
*** Create Excel to keep track of deleted observations
********************************************************************************
putexcel set "$output_data/MexDataCleansing.xlsx", sheet("MEX") replace

********************************************************************************	
*** Roberts and Tybout criteria
********************************************************************************
// Here we first combine all the data 
foreach y in 84 85 86 87 88 89 90{
	append using mex`y'output.dta
	save "$provisional/mexicomaster.dta", replace   
}
sort FOLIO CLASE PER
qui putexcel A2 =("Observations")
global obs = _N
qui putexcel B2 = $obs

***1. Drop missing plants according to R-T
gen GVO = VALPROEL + V92 + V93 + V94 + V84
gen INT = (MATPRICO + ENVASESU + COMBCONS + REFAUTIL + MATEACTI + OTGTMTSU) + VAENELCN + PROEL85 - PROEL86 + MATSU85 - MATSU86 + OTREX85 - OTREX86
gen CORVA = GVO - INT + INSERMAQ - GASTMAQU
gen TKS = V68 + V69 + V70 + V71 + V72 + (GTRENALQ/0.10)
gen FCOST = (GASTMAQU + GASERVRE + GTOTSEIM) + GTCOMVTA + GTSERPRO + GTOTECNO + GTFLETES + GTSENOIN + (V68 + V69 + V70 + V71 + V72)*0.10 + GTRENALQ
gen VCOST = INT + TOTREMUN
gen TCOST = FCOST + VCOST

lab var GVO "gross value of output"
lab var INT "intermediates"
lab var CORVA "value added corrected by maquila related flows"
lab var TKS "total capital stock"
lab var VCOST "variable costs"
lab var FCOST "fixed costs"
lab var TCOST "total costs"

foreach var in labor HOBRTRA SALOBRES CORVA TKS VCOST FCOST TCOST GVO INT {
	gen flag_`var' = .
	replace flag_`var' = 1 if (`var' == . | `var' == 0)
}
egen flag = rowtotal(flag_*)
drop if flag == 10
qui putexcel A3 =("Missing plants")
qui putexcel B3 = `r(N_drop)'
drop flag*

***2. Drop plants with negative value added
drop if CORVA < 0
qui putexcel A4 =("Negative value added")
qui putexcel B4 = `r(N_drop)'

***3. Elimination of odd observations
sort CLASE FOLIO PER
scalar define a = 0
foreach var in labor TOTREMUN VALPROEL VTAPROEL MATPRICO VAENELCN VAENELCO CAECCO CAEECN GTRENALQ ENVASESU COMBCONS REFAUTIL MATEACTI OTGTMTSU HOBRTRA TOHHOM{
	by CLASE FOLIO: gen growth_`var' = `var'/`var'[_n-1] if _n > 1 
	egen ip99`var' = pctile(growth_`var'), p(98)
	drop if growth_`var' > ip99`var' & growth_`var' ~=.
	scalar define a = a + `r(N_drop)'
	egen ip1`var' = pctile(growth_`var'), p(2)
	drop if growth_`var' < ip1`var' & growth_`var' ~=.
	scalar define a = a + `r(N_drop)'
}
drop ip* growth*
di a
qui putexcel A5 = ("Outliers")
qui putexcel B5 = a

***4. Incomplete series
by CLASE FOLIO: gen jumpyear = PER - PER[_n-1] if _n > 1
by CLASE FOLIO: drop if jumpyear > 1 & jumpyear ~= .
qui putexcel A6 = ("Incomplete series")
qui putexcel B6 = `r(N_drop)'
drop jumpyear

***5. Quasi missing or hardly operative
gen quasimiss = 1 if (labor == 0 | labor == .) & (HOBRTRA == 0 | HOBRTRA == .) & (SALOBRES == 0 | SALOBRES == .) & (CORVA == 0 | CORVA == .) & (VCOST == 0 | VCOST ==.) & (GVO == 0 | GVO == .) & (INT == 0 | INT ==.) & TKS > 0 & FCOST > 0 & TCOST > 0
gen hardlyoperative = 1 if  labor > 0 & HOBRTRA > 0 & SALOBRES > 0 & TKS > 0 & VCOST > 0 & FCOST > 0 & TCOST > 0 & INT < 0 & GVO < 0 & CORVA > 0.1*GVO
drop if quasimiss == 1 | hardlyoperative == 1
qui putexcel A7 = ("Quasi missing")
qui putexcel B7 = `r(N_drop)'
drop quasimiss hardlyoperative

********************************************************************************	
*** Sector
********************************************************************************
gen sector =.
replace sector = 1 if inrange(CLASE,2000,2299)
replace sector = 2 if inrange(CLASE,2300,2599)
replace sector = 3 if inrange(CLASE,2600,2699)
replace sector = 4 if inrange(CLASE,2700,2799)
replace sector = 5 if inrange(CLASE,2800,2999)
replace sector = 6 if inrange(CLASE,3000,3299)
replace sector = 7 if inrange(CLASE,3300,3499)
replace sector = 8 if inrange(CLASE,3500,3899)
replace sector = 9 if inrange(CLASE,3900,3999)

********************************************************************************	
*** Further cleaning
********************************************************************************
// First we try to keep only the variables we want to work on 
keep id year code sector labor nomwages wages sales nomcapstruc nomcapmach nomcapveh nomcap nominveststruc nominvestmach nominvestveh nominvest cap_struc cap_mach cap_veh invest_struc invest_mach invest_veh cap invest 

save "$provisional/mexicomaster2.dta", replace

// In order to make the data more comprehensible I sort the data by id and code, so that it looks like a panel data
sort id code, stable

// I notice that there are some data points with zero labor. This must be a mistake so I remove those items. This removes 1346 observations
drop if labor == 0
qui putexcel A8 = ("Zero labor")
qui putexcel B8 = `r(N_drop)'
// I also drop observations where the data is missing. Luckily this is not much and in total we have to drop only 87 observations all of which are dropped since 
// the wages are missing

scalar define i = 0
foreach var in wages id year code labor nomwages nomcapstruc nomcapmach nomcapveh nomcap nominveststruc nominvestmach nominvestveh{
	drop if missing(`var')
	scalar define i = i + `r(N_drop)'
}
qui putexcel A9 = ("Missing key variables")
qui putexcel B9 = i

count
qui putexcel A11 = ("Remaining observations")
qui putexcel B11 = `r(N)'

// In order to avoid confusion I save the "cleaned"/ "modified" data in a separate dta file known as mexicomaster3
save "$provisional/mexicomaster3.dta"

********************************************************************************	
*** Merge with master
********************************************************************************
// Now we want to merge the data with investmaster and so we create a row for the country name
generate str country = "MEX"

// We now alter our variable names to make it in according with that from previous investmaster
rename code ciiu
rename wages wage_bill
rename cap_struc capital_f_stru
rename cap_mach capital_f_mach
rename cap_veh capital_f_vehi
rename cap capital_f
rename invest_struc inv_stru
rename invest_mach inv_mach
rename invest_veh inv_vehi
rename invest inv_total

// We now drop the variables to ensure the list of variables are same for Mexico as was with Colombia and Chile
*drop nomwages nomcapstruc nomcapmach nomcapveh nomcap nominveststruc nominvestmach nominvestveh nominvest constcap_struc constcap_mach constcap_veh constcap
drop nomwages nomcapstruc nomcapmach nomcapveh nomcap nominveststruc nominvestmach nominvestveh nominvest 

save MEX_master, replace
use "$pathinit/Data/outputs/microdata/surveys/master/invest_master", clear
append using MEX_masterm clear
save "$pathinit/Data/outputs/microdata/surveys/master/invest_master", replace