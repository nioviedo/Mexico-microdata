********************************************************************************
*** Mexican investment data: preparation
********************************************************************************
*** Main inputs: mex84.dta-mex90.dta
*** Additional inputs: 
*** Output: mex84output.dta-mex90output.dta
*** Author: Utsav Bhadra
*** Notes: edited by Nicolas Oviedo - 06/14/2021
********************************************************************************
*** Set up
********************************************************************************
cls
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
	*global figures    "$pathinit/Data/figures/mexico"
	cap log close
	log using "$temp_file/step1mexico.log", append
}

if "$who" == "U" {
	global input_data "$pathinit"
}

cd "$input_data"

********************************************************************************	
*** Data prep
********************************************************************************
// First we call the data 

local myfilelist : dir "$input_data" files "*.dta"
tempfile cumulator
quietly save `cumulator', emptyok
local yr = 83
foreach file of local myfilelist {
	local name = "$input_data/`file'"
	di "`name'"
	use `file', clear
	local yr = `yr' + 1
	di `yr'
	
	// I create the variable id for the plant id. This will be useful to identify the plants
	generate id = FOLIO
	label variable id "plant id"
	
	// a variable year for the year 
	generate year = PER
	
	// the variable code is for the 4 digit industry code
	generate code = CLASE
	label variable code "4 digit industry code"
	
	// the variable labor for the total labour hours
	generate labor = TOPEOC
	label variable labor "total employment"
	
	// nomwages is the variable that is created for the total labor remunaration. Remember that it is in nominal terms
	generate nomwages = TOTREMUN
	label variable nomwages "nominal wages"
	
	// We use the wholesale price index as the deflator to get the real wages which we label as wages
	generate wages = (nomwages/PM) * 100
	label variable wages "real wages"
	
	// We also label as sales the total product sales for which I again use the wholesale price index as the deflator
	generate sales = (VTAPROEL/PM)*100
	label variable sales "product sales"
	
	// nomcapstruc, nomcapmach and nomcapveh are the capital stocks (book value) for structures, machinery and vehicles respectively. 
	// These 3 are added to get the total capital stock in nominal terms. We will later use the deflator from PWT to convert into real values
	generate nomcapstruc = V69
	label variable nomcapstruc "nominal capital (structures)"
	generate nomcapmach = V68
	label variable nomcapmach "nominal capital (machinery and equipment)"
	generate nomcapveh = V71
	label variable nomcapveh "nominal capital (vehicle and transport)"
	generate nomcap = nomcapstruc+ nomcapmach+ nomcapveh
	label variable nomcap "total nominal capital"
	
	// Now I try to create the investment in each ones of these. For this I follow the method similar to that in the Chile data which was presented 
	// in the appendix of the Baley, Blanco paper on Lumpy economies. So basically for each capital type the investment was the sum of the purchase 
	// new and used, add to this that part which was produced for own use and that improved by third parties. Finally, deduct the amount of that 
	// capital type which was sold. We do this for each of the three capital types and sum them to get the total investment. Again, remember that 
	// this is all in nominal and so we will later use the data of deflators from PWT for investment types to convert into real terms 
	generate nominveststruc = V82 + V87 + V93 + V97 -V102
	label variable nominveststruc "nominal investment in structures"
	generate nominvestmach = V81 + V86 + V92 + V96 - V101
	label variable nominvestmach "nominal investment in machinery and equipment"
	generate nominvestveh = V83+ V89 + V94 + V98 - V104
	label variable nominvestveh "nominal investment in vehicles and transport equipment"
	generate nominvest = nominveststruc + nominvestmach + nominvestveh
	label variable nominvest "total nominal investment"
	
	//Deflate
	//Nicolas: use producer price index to keep consistency with master. Note that there is one value of PPP per industrial activity
	generate cap_struc = (nomcapstruc/PPP)*100
	label variable cap_struc "real capital stock in structures"
	generate cap_mach = (nomcapmach/PPP)*100
	label variable cap_mach "real capital stock in machinery"
	generate cap_veh = (nomcapveh/PPP)* 100
	label variable cap_veh "real capital stock in vehicles"
	generate invest_struc = (nominveststruc/PPP) * 100
	label variable invest_struc "real investment in structures"
	generate invest_mach = (nominvestmach/PPP)* 100
	label variable invest_mach "real investment in machinery"
	generate invest_veh = (nominvestveh/PPP)* 100
	label variable invest_veh "real investment in vehicles"
	generate cap = cap_struc + cap_mach + cap_veh
	label variable cap "real total capital stock"
	generate invest = invest_struc + invest_mach + invest_veh
	label variable invest "total real investment"

	save "$output_data/mex`yr'output", replace
}


*** Cross check: deflator
/*	// We now use the specific PWT values to convert the capital stock and investment into real terms for each the three components and then add to get total 
	// real capital stock and real investment
	generate cap_struc = (nomcapstruc/0.00203045969828963)*100
	label variable cap_struc "real capital stock in structures"
	generate cap_mach = (nomcapmach/0.0087883323431015)*100
	label variable cap_mach "real capital stock in machinery"
	generate cap_veh = (nomcapveh/0.00745917018502951)* 100
	label variable cap_veh "real capital stock in vehicles"
	generate invest_struc = (nominveststruc/0.0023178190458566) * 100
	label variable invest_struc "real investment in structures"
	generate invest_mach = (nominvestmach/0.010998772457242)* 100
	label variable invest_mach "real investment in machinery"
	generate invest_veh = (nominvestveh/0.00745917018502951)* 100
	label variable invest_veh "real investment in vehicles"
	generate cap = cap_struc + cap_mach + cap_veh
	label variable cap "real total capital stock"
	generate invest = invest_struc + invest_mach + invest_veh
	label variable invest "total real investment"
	*/