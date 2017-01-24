clear all
cap cd "C:\Users\scottb131\Dropbox\Texas Job Search - New"
cap cd "C:\Users\Scott\Dropbox\Texas Job Search - New"
cap cd "C:\Users\srb834\Dropbox\Texas Job Search - New"
cap cd "/Users/afradkin/Dropbox/Texas_Job_Search_New/"

*** Taken from 2_Soph_Weeks_Left_OLS.do
cap use "Texas_UI_Data/soph_readyforweeklyregs.dta"
set more off
cap gen monthyear=mofd(date)
merge m:1 monthyear using "Other_Data\south_vacancies.dta"
drop if _merge==2
drop _merge 
cap gen lvacancies = log(vacancies)
cap gen ltightness = log(vacancies/unemployed)

foreach var of varlist num_on_ui* {
	replace `var' = `var'*(population)
}

*drop if msa_code == 13
*drop msas13 msasdate13 msas19 msasdate19
drop mms*
cap gen scunemployed = unemployed/500
cap gen sclabor_force = labor_force/500
cap gen not_on_ui = unemployed - total_on_ui
cap gen lnot_on_ui=log(not_on_ui)
drop employed
gen employed = labor_force - unemployed
cap gen lemployed = log(employed)
cap tab week, gen(wfe)
cap tab year, gen(yfe)
cap tab month, gen(mfe)
cap tab year_month, gen(ymfe)
label var lunemployed "Log Unemployed"
label var ltotal_on_ui "Log Total On UI"
label var ljob_search "Job Search"
label var all_extensions_4week "4 Weeks After Ext."
cap egen yearmsa = group(year msa_code)

*** Scale To Make Reasonable Coefs ***
cap gen scnot_on_ui = not_on_ui/500
cap gen sctotal_on_ui = total_on_ui/500
cap gen scemployed = employed/500

*** Check here that everything adds up! 
cap egen check_sum1 = rowtotal(num_weeks_on1-num_weeks_on120 num_weeks_on0)
cap replace check_sum1 = check_sum1*population 

cap egen check_sum2 = rowtotal(num_on_ui0-num_on_ui87)
cap replace check_sum2 = check_sum2 

sum total_on_ui check_sum1 check_sum2

foreach var of varlist num_ui_0_10 - num_ui_80_90 {
	replace `var' = `var'*population/500
}

cap egen greater_than_30 = rowtotal(num_ui_30_40 - num_ui_80_90)
cap egen greater_than_40 = rowtotal(num_ui_40_50 - num_ui_80_90)
cap egen greater_than_50 = rowtotal(num_ui_50_60 - num_ui_80_90)

cap egen weekson7 = rowtotal(num_weeks_on1 - num_weeks_on7 num_weeks_on0)
replace weekson7 = population * weekson7
cap egen weeksleft5 = rowtotal(num_on_ui0 - num_on_ui5)
cap gen weeksonrest = total_on_ui - weekson7 - weekson14 - weekson21 - weeksleft5
foreach var of varlist weekson* weeksleft* {
	replace `var' = `var'/500
}

tsset msa_code date, daily delta(7)

cap gen altweeksonleft5=(l4.weeksleft5+l3.weeksleft5+l2.weeksleft5)/3
cap gen indaltweeksonleft5=all_extensions_4week*altweeksonleft5

******************************************************************
cap cd "C:\Users\scottb131\Dropbox\Texas Job Search - New\src2\latex\Final_Figures_Tables"
cap cd "C:\Users\Scott\Dropbox\Texas Job Search - New\src2\latex\Final_Figures_Tables"
cap cd "C:\Users\srb834\Dropbox\Texas Job Search - New\src2\latex\Final_Figures_Tables"
cap cd "/Users/afradkin/Dropbox/Texas_Job_Search_New/src2/latex/Final_Figures_Tables"

cap gen lagindsctotal_on_ui = all_extensions_and_exp_4week*l4.sctotal_on_ui
cap gen lagindsc010 = all_extensions_and_exp_4week*l4.num_ui_0_10
cap gen lagindsc1020 = all_extensions_and_exp_4week*l4.num_ui_10_20
cap gen lagindsc2030 = all_extensions_and_exp_4week*l4.num_ui_20_30
cap gen lagindsc30up = all_extensions_and_exp_4week*l4.greater_than_30
cap gen lagnum_ui_0_10 = l4.num_ui_0_10
cap gen lagnum_ui_10_20 = l4.num_ui_10_20
cap gen lagnum_ui_20_30 = l4.num_ui_20_30
cap gen laggreater_than_30 = l4.greater_than_30

foreach var of varlist lag* {
	cap replace `var' = 0 if `var'==.
}

cap gen indscunemployed_only = all_extensions_4week*scunemployed
cap gen indsctotal_on_ui_only = all_extensions_4week*sctotal_on_ui
cap gen indscunemployed = all_extensions_and_exp_4week*scunemployed
cap gen indsctotal_on_ui = all_extensions_and_exp_4week*sctotal_on_ui
cap gen indscnot_on_ui = all_extensions_and_exp_4week*scnot_on_ui
cap gen indscemployed = all_extensions_and_exp_4week*scemployed 
cap gen indsctotal_on_ui_2week = all_extensions_and_exp_2week*sctotal_on_ui

cap gen indsc010 = all_extensions_and_exp_4week*num_ui_0_10
cap gen indsc1020 = all_extensions_and_exp_4week*num_ui_10_20
cap gen indsc2030 = all_extensions_and_exp_4week*num_ui_20_30
cap gen indsc30up = all_extensions_and_exp_4week*greater_than_30

cap gen all_ext_X_unemp = all_extensions_4week*unemp_rate

gen all_extensions_and_exp_8week = all_extensions_and_exp_1week
replace all_extensions_and_exp_8week = l.all_extensions_and_exp_8week if l.all_extensions_and_exp_8week==1 & l8.all_extensions_and_exp_8week==0

** Google Issued a Correction. We're creating a dummy for it and interactions
gen dum2011 = (year==2011)
egen msa_dum2011 = group(msa_code dum2011)

gen extensions_unemp = all_extensions_and_exp_4week*scunemployed

foreach var of varlist num_ui_0_10_weeks num_ui_10_20_weeks num_ui_20_30_weeks greater_than_30 {
	gen frac_`var' = `var'*1000/population
}
foreach var of varlist employed not_on_ui total_on_ui weekson7 {
	gen frac_`var' = `var'/population
}
gen frac_not_in_lab_force = 1 - frac_employed - frac_total_on_ui - frac_not_on_ui

**Quadratic trend
foreach var of varlist msasdate1-msasdate19 {
	gen `var'_2 = `var'^2
}

label var all_extensions_and_exp_1week "One Wks Post Legislation"
label var all_extensions_and_exp_2week "Two Wks Post Legislation"
label var all_extensions_and_exp_4week "Four Wks Post Legislation"
label var num_ui_0_10_weeks "Log(Number 0-10 Weeks Left)"
label var num_ui_10_20_weeks "Log(Number 10-20 Weeks Left)"
label var num_ui_20_30_weeks "Log(Number 20-30 Weeks Left)"
label var greater_than_30 "Log(Number 30+ Weeks Left)"
label var scnot_on_ui "Log(Number Not on UI)"
label var scemployed "Log(Number Employed)"
label var lunemployed "Log(Number Unemployed)"
label var unemp_rate "Unemp. Rate"
label var all_ext_X_unemp "Post Expansion*Unemp"
label var all_extensions_4week "Four Wks Post Expansion"
label var extensions_unemp "Expansion * Num. Unemployed"
label var frac_not_in_lab_force "Not in Labor Force"


compress
cap save "C:\Users\Scott\Dropbox\Texas Job Search - New\Texas_UI_Data\working_data_regressions.dta", replace
cap save "C:\Users\scottb131\Dropbox\Texas Job Search - New\Texas_UI_Data\working_data_regressions.dta", replace
cap save "C:\Users\srb834\Dropbox\Texas Job Search - New\Texas_UI_Data\working_data_regressions.dta", replace
cap save "/Users/afradkin/Dropbox/Texas_Job_Search_New/Texas_UI_Data/working_data_regressions.dta", replace

stop
******************************************************************
    ******************* Table 4 NLLS *********************
clear all
cap use "C:\Users\scottb131\Dropbox\Texas Job Search - New\Texas_UI_Data\working_data_regressions.dta"
cap use "C:\Users\srb834\Dropbox\Texas Job Search - New\Texas_UI_Data\working_data_regressions.dta"
cap use "/Users/afradkin/Dropbox/Texas_Job_Search_New/Texas_UI_Data/working_data_regressions.dta"
cap cd "/Users/afradkin/Dropbox/Texas_Job_Search_New/src2/latex/Final_Figures_Tables"
cap cd "C:\Users\scottb131\Dropbox\Texas Job Search - New\src2\latex\Final_Figures_Tables"
cap cd "C:\Users\srb834\Dropbox\Texas Job Search - New\src2\latex\Final_Figures_Tables"

eststo clear

eststo: qui nl (ljob_search = 1 + {xb:holiday msas1-msas18 msasdate1-msasdate18 ymfe1-ymfe62} + log({xb: sctotal_on_ui scnot_on_ui scemployed})), initial(xb_scemployed .4) cluster(msa)
matrix moo = e(b)
matrix coefs = moo[1,colnumb(moo,"xb_sctotal_on_ui: _cons")...]
local ratunemptoemp = coefs[1,2]/coefs[1,3]
local ratuinotui = coefs[1,1]/coefs[1,2]
qui estadd local msafe "Yes"
qui estadd local myfe "Yes"
qui estadd scalar ratu = `ratunemptoemp'
qui estadd scalar ratemp = `ratuinotui'

eststo: qui nl (ljob_search = 1 + {xb:holiday msas1-msas18 msasdate1-msasdate18 ymfe1-ymfe62 all_extensions_and_exp_4week} + log({xb: sctotal_on_ui scnot_on_ui scemployed})), initial(xb_sctotal_on_ui .4 xb_scnot_on_ui .4) cluster(msa)
matrix moo = e(b)
matrix coefs = moo[1,colnumb(moo,"xb_sctotal_on_ui: _cons")...]
local ratunemptoemp = coefs[1,2]/coefs[1,3]
local ratuinotui = coefs[1,1]/coefs[1,2]
qui estadd local msafe "Yes"
qui estadd local myfe "Yes"
qui estadd scalar ratu = `ratunemptoemp'
qui estadd scalar ratemp = `ratuinotui'

eststo: qui nl (ljob_search = 1 + {xb:holiday msas1-msas18 msasdate1-msasdate18 ymfe1-ymfe62} + log({xb: num_ui_0_10_weeks num_ui_10_20_weeks num_ui_20_30_weeks greater_than_30 scnot_on_ui scemployed})), initial(xb_scemployed .1 xb_scnot_on_ui 1) cluster(msa)
qui estadd local msafe "Yes"
qui estadd local myfe "Yes"

eststo: qui nl (ljob_search = 1 + {xb:holiday msas1-msas18 msasdate1-msasdate18 ymfe1-ymfe62 all_extensions_and_exp_4week} + log({xb: num_ui_0_10_weeks num_ui_10_20_weeks num_ui_20_30_weeks greater_than_30 scnot_on_ui scemployed})), initial(xb_scemployed .1 xb_scnot_on_ui 1) cluster(msa)
qui estadd local msafe "Yes"
qui estadd local myfe "Yes"


esttab using Tables/nllsregs.tex, se title(Effect of UI Status and Composition on Job Search (NLLS) \label{tab:nlls}) keep("xb_sctotal_on_ui: _cons" "xb_scnot_on_ui: _cons" "xb_scemployed: _cons" "xb_all_extensions_and_exp_4week: _cons" "xb_greater_than_30:_cons" "xb_num_ui_0_10_weeks:_cons" "xb_num_ui_10_20_weeks:_cons" "xb_num_ui_20_30_weeks:_cons") coeflabels(xb_sctotal_on_ui:_cons "Number on UI" xb_scnot_on_ui:_cons "Not on UI" xb_scemployed:_cons "Number Employed" xb_all_extensions_and_exp_4week:_cons "Post Legislation" xb_greater_than_30:_cons "Over 30 Weeks Left" xb_num_ui_0_10_weeks:_cons "0-10 Weeks Left" xb_num_ui_10_20_weeks:_cons "10-20 Weeks Left" xb_num_ui_20_30_weeks:_cons "20-30 Weeks Left" ) scalars( "ratu UI Recipients/Employed" "ratemp UI Recipients/Non-UI Unemployed" "hline \hline \vspace{-2mm}" "msafe DMA FE and Trend" "myfe Year-Month FE" "r2 R-Squared") nomtitles star(* 0.10 ** 0.05 *** .01) nonotes addnote("} \floatfoot{Notes: Dependent variable is log(GJSI) at DMA-week level. Analysis spans all Texas DMAs from 2006-2011. Number on UI, Not on UI, and Number Employed are the total number of individuals in each category. Post Legislation is the week of and three weeks following legislation. Unemployed/Employed gives the relative levels of search activity across types. Standard Errors Clustered at DMA level. \\ * p$<$0.10, ** p$<$0.05, *** p$<$0.01} {") obslast replace label gaps

**********************************************************************************************
    ******************* Appendix Table 5 - OLS Version of Table 4 *********************

clear all
cap use "C:\Users\scottb131\Dropbox\Texas Job Search - New\Texas_UI_Data\working_data_regressions.dta"
cap use "C:\Users\Scott\Dropbox\Texas Job Search - New\Texas_UI_Data\working_data_regressions.dta"
cap use "C:\Users\srb834\Dropbox\Texas Job Search - New\Texas_UI_Data\working_data_regressions.dta"
cap use "/Users/afradkin/Dropbox/Texas_Job_Search_New/Texas_UI_Data/working_data_regressions.dta"
cap cd "/Users/afradkin/Dropbox/Texas_Job_Search_New/src2/latex/Final_Figures_Tables"
cap cd "C:\Users\scottb131\Dropbox\Texas Job Search - New\src2\latex\Final_Figures_Tables"
cap cd "C:\Users\Scott\Dropbox\Texas Job Search - New\src2\latex\Final_Figures_Tables"
cap cd "C:\Users\srb834\Dropbox\Texas Job Search - New\src2\latex\Final_Figures_Tables"


label var frac_not_on_ui "Frac Not on UI"
label var frac_employed "Frac Employed"
label var frac_total_on_ui "Frac On UI"
label var frac_num_ui_0_10_weeks "Frac Under 10 Wks Left"
label var frac_num_ui_10_20_weeks "Frac 10-19 Wks Left"
label var frac_num_ui_20_30_weeks "Frac 20-29 Wks Left"
label var frac_greater_than_30 "Frac Over 30 Wks Left"
label var all_extensions_4week "Post Expansion"

eststo clear

eststo: qui areg ljob_search frac_total_on_ui frac_not_on_ui frac_not_in_lab_force holiday msas*, ab(year_month)
qui estadd local msafe "Yes"
qui estadd local myfe "Yes"

eststo: qui areg ljob_search frac_total_on_ui frac_not_on_ui frac_not_in_lab_force all_extensions_and_exp_4week holiday msas*, ab(year_month)
qui estadd local msafe "Yes"
qui estadd local myfe "Yes"

eststo: qui areg ljob_search frac_not_on_ui frac_not_in_lab_force frac_num_ui_0_10_weeks frac_num_ui_10_20_weeks frac_num_ui_20_30_weeks frac_greater_than_30 holiday msas*, ab(year_month)
qui estadd local msafe "Yes"
qui estadd local myfe "Yes"

eststo: qui areg ljob_search frac_not_on_ui frac_not_in_lab_force frac_num_ui_0_10_weeks frac_num_ui_10_20_weeks frac_num_ui_20_30_weeks frac_greater_than_30 all_extensions_and_exp_4week holiday msas*, ab(year_month)
qui estadd local msafe "Yes"
qui estadd local myfe "Yes"

esttab using Tables/ols_regs.tex, se title(Effect of UI on Job Search (OLS)\label{tab:olsregs}) keep(all_extensions_and_exp_4week frac_not_on_ui frac_total_on_ui frac_num_ui_0_10_weeks frac_num_ui_10_20_weeks frac_num_ui_20_30_weeks frac_greater_than_30) coeflabels(frac_greater_than_30 "Over 30 Weeks Left" frac_num_ui_0_10_weeks "0-10 Weeks Left" frac_num_ui_10_20_weeks "10-20 Weeks Left" frac_num_ui_20_30_weeks "20-30 Weeks Left"  frac_not_on_ui "Not on UI" frac_total_on_ui "Total on UI" frac_employed "Number Employed" all_extensions_and_exp_4week "Post Legislation") scalars("msafe DMA FE" "myfe Year-Month FE" "r2 R-Squared") nomtitles star(* 0.10 ** 0.05 *** .01) nonotes addnote("} \floatfoot{Notes: Dependent variable is log(GJSI) at DMA-week level. Analysis spans all Texas DMAs from 2006-2011. `Frac' variables represent the fraction of the total population belonging to each category. Post Legislation is the week of and three weeks following legislation. Standard Errors Clustered at DMA level. \\ * p$<$0.10, ** p$<$0.05, *** p$<$0.01} {") obslast replace label gaps wrap


**********************************************************************************************
    ******************* Table XX - Table by Individual Week Bins *********************
clear all
cap use "C:\Users\scottb131\Dropbox\Texas Job Search - New\Texas_UI_Data\working_data_regressions.dta"
cap use "C:\Users\Scott\Dropbox\Texas Job Search - New\Texas_UI_Data\working_data_regressions.dta"
cap use "C:\Users\srb834\Dropbox\Texas Job Search - New\Texas_UI_Data\working_data_regressions.dta"
cap use "/Users/afradkin/Dropbox/Texas_Job_Search_New/Texas_UI_Data/working_data_regressions.dta"
cap cd "/Users/afradkin/Dropbox/Texas_Job_Search_New/src2/latex/Final_Figures_Tables"
cap cd "C:\Users\scottb131\Dropbox\Texas Job Search - New\src2\latex\Final_Figures_Tables"
cap cd "C:\Users\Scott\Dropbox\Texas Job Search - New\src2\latex\Final_Figures_Tables"
cap cd "C:\Users\srb834\Dropbox\Texas Job Search - New\src2\latex\Final_Figures_Tables"


foreach var of varlist employed not_on_ui total_on_ui {
	cap gen frac_`var' = `var'/population
}

foreach var of varlist num_on_ui1-num_on_ui85 {
	gen bin_`var' = `var'
}

foreach var of varlist num_on_ui1-num_on_ui85 {
	gen frac_bin_`var' = `var'/population
}

forvalues x = 5(5)85 {
	local y = `x' - 4
	egen bin_`y'_`x' = rowtotal(bin_num_on_ui`y' - bin_num_on_ui`x')
	replace bin_`y'_`x' = bin_`y'_`x'/500
}

forvalues x = 5(5)85 {
	local y = `x' - 4
	egen frac_bin_`y'_`x' = rowtotal(frac_bin_num_on_ui`y' - frac_bin_num_on_ui`x')
}

*eststo: qui areg ljob_search frac_employed frac_not_on_ui frac_bin_1_5-frac_bin_81_85 holiday population msasdate1-msasdate18 i.msa_code, ab(year_month) cluster(msa)


eststo: qui nl (ljob_search = 1 + {xb:holiday msas1-msas17 msasdate1-msasdate18 ymfe1-ymfe62 all_extensions_and_exp_4week} + log({xb: bin_1_5- bin_81_85 scnot_on_ui scemployed})), initial(xb_scemployed .1 xb_scnot_on_ui 1) cluster(msa)

esttab using Tables/week_bins.tex, se title(Effect of UI on Job Search by Week Bin\label{tab:weekbins}) keep(frac_employed frac_not_on_ui frac_bin_*) coeflabels(frac_greater_than_30 "Over 30 Weeks Left" frac_num_ui_0_10_weeks "0-10 Weeks Left" frac_num_ui_10_20_weeks "10-20 Weeks Left" frac_num_ui_20_30_weeks "20-30 Weeks Left"  frac_not_on_ui "Not on UI" frac_total_on_ui "Total on UI" frac_employed "Number Employed" all_extensions_and_exp_4week "Post Legislation") scalars("msafe MSA Trend and FE" "myfe Year-Month FE" "r2 R-Squared") nomtitles star(* 0.10 ** 0.05 *** .01) nonotes addnote("Standard Errors Clustered at DMA level." "* p$<$0.10, ** p$<$0.05, *** p$<$0.01") obslast replace label gaps


*matrix temp = e(b)
*matrix coefs = temp[1,colnumb(temp,"xb_bin_1_5: _cons")...]
*di coefs[1,1]
*local ratunemptoemp = coefs[1,2]/coefs[1,3]

matrix est = e(b)
matrix var = e(V)
gen variance = .
gen estimate = .
gen standerror=.
gen low_conf = .
gen high_conf = .
forvalues y = 1/17 {
	replace variance = var[`y'+98, `y'+98] in `y'
	replace estimate = est[1, `y'+98] in `y'
}
replace standerror = variance^.5
replace low_conf = estimate-1.96*standerror
replace high_conf = estimate+1.96*standerror

gen weeks_left = .
forvalues x=1/17 {
	replace weeks_left = (`x'-1)*5 +1 in `x'
}

label var estimate "Relative Job Search Intensity"
label var weeks_left "Weeks of UI Benefits Left"
graph twoway (line estimate weeks_left) (line low_conf weeks_left, clp(dash)) (line high_conf weeks_left, clp(dash)) in 1/17, scheme(s2mono) legend(off) ytitle("Relative Job Search Intensity")
graph export Figures/Weeks_left_bin_effects.png, width(1200) height(600) replace

**** Appendix NLLS: NO Trends ***
    ******************* Table 4 NLLS *********************
clear all
cap use "C:\Users\scottb131\Dropbox\Texas Job Search - New\Texas_UI_Data\working_data_regressions.dta"
cap use "C:\Users\srb834\Dropbox\Texas Job Search - New\Texas_UI_Data\working_data_regressions.dta"
cap use "/Users/afradkin/Dropbox/Texas_Job_Search_New/Texas_UI_Data/working_data_regressions.dta"
cap cd "/Users/afradkin/Dropbox/Texas_Job_Search_New/src2/latex/Final_Figures_Tables"
cap cd "C:\Users\scottb131\Dropbox\Texas Job Search - New\src2\latex\Final_Figures_Tables"
cap cd "C:\Users\srb834\Dropbox\Texas Job Search - New\src2\latex\Final_Figures_Tables"

eststo clear

eststo: qui nl (ljob_search = 1 + {xb:holiday msas1-msas18 ymfe1-ymfe62} + log({xb: sctotal_on_ui scnot_on_ui scemployed})), initial(xb_scemployed .4) cluster(msa)
matrix moo = e(b)
matrix coefs = moo[1,colnumb(moo,"xb_sctotal_on_ui: _cons")...]
local ratunemptoemp = coefs[1,2]/coefs[1,3]
local ratuinotui = coefs[1,1]/coefs[1,2]
qui estadd local msafe "Yes"
qui estadd local myfe "Yes"
qui estadd scalar ratu = `ratunemptoemp'
qui estadd scalar ratemp = `ratuinotui'

eststo: qui nl (ljob_search = 1 + {xb:holiday msas1-msas18 ymfe1-ymfe62 all_extensions_and_exp_4week} + log({xb: sctotal_on_ui scnot_on_ui scemployed})), initial(xb_sctotal_on_ui .4 xb_scnot_on_ui .4) cluster(msa)
matrix moo = e(b)
matrix coefs = moo[1,colnumb(moo,"xb_sctotal_on_ui: _cons")...]
local ratunemptoemp = coefs[1,2]/coefs[1,3]
local ratuinotui = coefs[1,1]/coefs[1,2]
qui estadd local msafe "Yes"
qui estadd local myfe "Yes"
qui estadd scalar ratu = `ratunemptoemp'
qui estadd scalar ratemp = `ratuinotui'

eststo: qui nl (ljob_search = 1 + {xb:holiday msas1-msas18 ymfe1-ymfe62} + log({xb: num_ui_0_10_weeks num_ui_10_20_weeks num_ui_20_30_weeks greater_than_30 scnot_on_ui scemployed})), initial(xb_scemployed .1 xb_scnot_on_ui 1) cluster(msa)
qui estadd local msafe "Yes"
qui estadd local myfe "Yes"

eststo: qui nl (ljob_search = 1 + {xb:holiday msas1-msas18 ymfe1-ymfe62 all_extensions_and_exp_4week} + log({xb: num_ui_0_10_weeks num_ui_10_20_weeks num_ui_20_30_weeks greater_than_30 scnot_on_ui scemployed})), initial(xb_scemployed .1 xb_scnot_on_ui 1) cluster(msa)
qui estadd local msafe "Yes"
qui estadd local myfe "Yes"


esttab using Tables/nllsregs_notrends.tex, se title(Effect of UI Status and Composition on Job Search (NLLS) \label{tab:nlls}) keep("xb_sctotal_on_ui: _cons" "xb_scnot_on_ui: _cons" "xb_scemployed: _cons" "xb_all_extensions_and_exp_4week: _cons" "xb_greater_than_30:_cons" "xb_num_ui_0_10_weeks:_cons" "xb_num_ui_10_20_weeks:_cons" "xb_num_ui_20_30_weeks:_cons") coeflabels(xb_sctotal_on_ui:_cons "Number on UI" xb_scnot_on_ui:_cons "Not on UI" xb_scemployed:_cons "Number Employed" xb_all_extensions_and_exp_4week:_cons "Post Legislation" xb_greater_than_30:_cons "Over 30 Weeks Left" xb_num_ui_0_10_weeks:_cons "0-10 Weeks Left" xb_num_ui_10_20_weeks:_cons "10-20 Weeks Left" xb_num_ui_20_30_weeks:_cons "20-30 Weeks Left" ) scalars( "ratu UI Recipients/Employed" "ratemp UI Recipients/Non-UI Unemployed" "hline \hline \vspace{-2mm}" "msafe DMA FE and Trend" "myfe Year-Month FE" "r2 R-Squared") nomtitles star(* 0.10 ** 0.05 *** .01) nonotes addnote("} \floatfoot{Notes: Dependent variable is log(GJSI) at DMA-week level. Analysis spans all Texas DMAs from 2006-2011. Number on UI, Not on UI, and Number Employed are the total number of individuals in each category. Post Legislation is the week of and three weeks following legislation. Unemployed/Employed gives the relative levels of search activity across types. Standard Errors Clustered at DMA level. \\ * p$<$0.10, ** p$<$0.05, *** p$<$0.01} {") obslast replace label gaps