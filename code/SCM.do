clear all
set more off

program main_scm
    * Definition of research designs
	local control_vars = "edad married cantidad_personas hay_menores y_hogar"
	local labor_vars   = "trabajo horas_trabajo"
	local educ_vars    = "educ_HS_or_more educ_more_HS"
	local outcome_vars = "`labor_vars' " + "`educ_vars'"
	local labor_stubs  = `" "Employment" "Hours-worked" "'
	local educ_stubs   = `" "High-school" "Some-college" "'
	
	local legend_rivera = "Rivera"
	local legend_salto  = "Salto"
	
	local q_date_is_chpr  "2002q1"
	local q_date_rivera  "2010q3"
	local q_date_salto "2013q1"
	
	local s_date_is_chpr "2002h1"
	local s_date_rivera "2010h2"
	local s_date_salto "2013h1"
	
	local y_date_is_chpr 2002 
	local y_date_rivera 2010 
	local y_date_salto 2013 
	
	local restr_rivera "restr((dpto == 1 | loc_code == 330020 | loc_code == 1630020))"
	local restr_salto ""
	
	foreach city in rivera salto {
	    foreach group_vars in educ labor {
			
			foreach special_legend in "" "placebo" {
			
				if "`special_legend'" == "placebo" {
				
				    if "`group_vars'" == "labor" {
					    local sample_restr = "keep if hombre == 0 & edad > 40"
					}
					else {
					    local sample_restr = "keep if hombre == 0 & edad > 40"
					}
				}
				else {
				    if "`group_vars'" == "labor" {
					    local sample_restr = "keep if hombre == 0 & inrange(edad, 14, 40)"
					}
					else {
					    local sample_restr = "keep if hombre == 0 & inrange(edad, 18, 25)"
					}
				}
					
			build_synth_control, outcomes(`outcome_vars') city(`city') event_date(`q_date_`city'') ///
				time(anio_qtr) controls(`control_vars') `restr_`city'' special_legend(`special_legend') ///
				sample_restr(`sample_restr')
				
			build_synth_control, outcomes(`outcome_vars') city(`city') event_date(`s_date_`city'') ///
				time(anio_sem) controls(`control_vars') `restr_`city'' special_legend(`special_legend') ///
				sample_restr(`sample_restr')
				
			build_synth_control, outcomes(`outcome_vars') city(`city') event_date(`y_date_`city'') ///
				time(anio)     controls(`control_vars') `restr_`city'' special_legend(`special_legend') ///
				sample_restr(`sample_restr')
			

			plot_scm, outcomes(``group_vars'_vars') city(`city') event_date(`q_date_`city'') ///
				time(anio_qtr) groups_vars(`group_vars') city_legend(`legend_`city'')        ///
				stub_list(``group_vars'_stubs') special_legend(`special_legend')
		 
			plot_scm, outcomes(``group_vars'_vars') city(`city') event_date(`s_date_`city'') ///
				time(anio_sem) groups_vars(`group_vars') city_legend(`legend_`city'')           ///
				stub_list(``group_vars'_stubs') special_legend(`special_legend')

			plot_scm, outcomes(``group_vars'_vars') city(`city') event_date(`y_date_`city'') ///
				time(anio)     groups_vars(`group_vars') city_legend(`legend_`city'')         ///
				stub_list(``group_vars'_stubs') special_legend(`special_legend')
		}
		
	grc1leg scm_`city'_`group_vars'_anio_qtr scm_`city'_`group_vars'_anio_qtrplacebo, cols(2) ///
	    legendfrom(scm_`city'_`group_vars'_anio_qtr) position(6) ///
	    graphregion(color(white))
	graph display, ysize(6.5) xsize(9.5)
	graph export ../figures/scm_`city'_`group_vars'_anio_qtr.pdf, replace

	grc1leg scm_`city'_`group_vars'_anio_sem scm_`city'_`group_vars'_anio_semplacebo, cols(2) ///
	    legendfrom(scm_`city'_`group_vars'_anio_sem) position(6) ///
	    graphregion(color(white))
	graph display, ysize(6.5) xsize(9.5)
	graph export ../figures/scm_`city'_`group_vars'_anio_sem.pdf, replace

	grc1leg scm_`city'_`group_vars'_anio scm_`city'_`group_vars'_anioplacebo, cols(2) ///
	    legendfrom(scm_`city'_`group_vars'_anio) position(6) ///
	    graphregion(color(white))
	graph display, ysize(6.5) xsize(9.5)
	graph export ../figures/scm_`city'_`group_vars'_anio.pdf, replace
	
	}
	}
end

program build_synth_control
	syntax [if], outcomes(string) controls(string) city(string) event_date(string) ///
	    time(str) sample_restr(str) [special_legend(string) restr(string)]

    use "..\base\ech_final_98_2016.dta", clear
    `sample_restr'

	* Setup time settings by: qtr, sem, yr
	if "`time'" == "anio_qtr" {
			local weight pesotri
			local lag_list `" 2 4 6 8 10 12 14 16 18 20 22 24 26 28 30 32"' //`" 1 3 5 7 "'
			local range "if inrange(`time', tq(`event_date') - 32,tq(`event_date') + 12) "
			qui sum `time' `range'	
			local min_year = year(dofq(r(min)))
			qui sum `time'  if  `time' == tq(`event_date')
		}
		else if "`time'" == "anio_sem" {
			local weight pesosem
			local lag_list `" 2 4 6 8 10 12 14 16 "' //`" 5 6 7 8 9 10 11 12 "'
			local range "if inrange(`time', th(`event_date') - 16,th(`event_date') + 6) "
			qui sum `time' `range'	
			local min_year = year(dofh(r(min)))
			qui sum `time'  if  `time' == th(`event_date')		
		}
		else {
			local weight pesoan
			local lag_list `" 2 4 6 8 "' //`" 3 4 5 6 "'
			local range "if inrange(`time', `event_date' - 8, `event_date' + 3) "
			qui sum `time' `range'	
			local min_year = r(min)
			qui sum `time'  if  `time' == `event_date'	
		}
	local event_date = r(mean)		
	keep `range'
	cap drop if `restr'

	* Setup the controls to be used depending on the period
	if `min_year' < 2001  {
		local control_vars " c98_* "
		}
	else if `min_year' >=2001 & `min_year' < 2006  {
		local control_vars " c98_* c01_* "
		}
	else {
		local control_vars " c98_* c01_* c06_* "
		}
		
	* Get identifier of treated unit, and collapse data by time and loc_code
	qui sum loc_code if treatment_`city'==1 | placebo_`city'
	local trunit = r(mean)
	collapse (mean) `controls' `control_vars' `outcomes' treatment_`city' `if' [aw = `weight'], by(`time' loc_code)
		
	* Check the panel is balanced, this is for the synthetic control to work
	xtset loc_code `time'
	local num_`time's = r(tmax) - r(tmin) + 1
	bysort loc_code: gen num_`time' = _N
	keep if num_`time' == `num_`time's'  /*for proper geocodes this should be an assertion*/

	* Check the panel is balanced against missing values
	local n_outcomes: word count `outcomes'
	forval i = 1/`n_outcomes' {
		local outcome_var: word `i' of `outcomes' 
		drop if `outcome_var'==.
	}
	bysort loc_code: replace num_`time' = _N
	keep if num_`time' == `num_`time's' /*for proper geocodes this should be an assertion*/

	save "../base/donorpool_`city'_`time'`special_legend'.dta", replace
	
	* Create the synth control for each outcome
	forval i = 1/`n_outcomes' {
		local var: word `i' of `outcomes'
		use "../base/donorpool_`city'_`time'`special_legend'.dta", clear
		
		* Create lags of current outcome
		local lags "" // so that we do not add lags of other outcomes
		local i=1
		foreach j of numlist `lag_list' {
			local lag`i' = `event_date' - `j'
			local lags  = "`lags'" + " `var'(`lag`i'') "
			local i = `i'+1
		}
		* We need unabbreviated variables for the synth
		qui desc `control_vars', f varlist
		local control_vars_exp `r(varlist)'

		* Run SCM, save data for this outcome, and rename vars
		qui synth `var' `controls' `control_vars_exp' `lags', ///
			trunit(`trunit') trperiod(`event_date') ///
			keep("../temp/synth_`city'_`var'`special_legend'.dta", replace)	

		use "../temp/synth_`city'_`var'`special_legend'.dta", clear
		rename (_Co_Number _time _Y_treated _Y_synthetic) ///
			(geocode `time' `city'_`var'`special_legend' s_`city'_`var'`special_legend')
		drop if `time'==.
		drop geocode _W_Weight
		save "../temp/synth_`city'_`var'`special_legend'.dta", replace
	}

	* Construct dataset with all outcomes for a given research design: city-time
	local outcome_var: word 1 of `outcomes' 
	use "../temp/synth_`city'_`outcome_var'`special_legend'", clear

	forval i = 2/`n_outcomes' {
		local outcome_var: word `i' of `outcomes' 
		merge 1:1 `time' using "../temp/synth_`city'_`outcome_var'`special_legend'", nogen
	}
	save "../derived/controltrends_`city'_`time'`special_legend'.dta", replace
end

program plot_scm
    syntax, outcomes(string) city(string) city_legend(string) event_date(string) ///
	    stub_list(string) time(str) groups_vars(str) [special_legend(string)]
	
	use "../derived/controltrends_`city'_`time'`special_legend'.dta", clear

	* Setup time settings by: qtr, sem, yr
    if "`time'" == "anio_qtr" {
	    format `time' %tq 
		local vertical = tq(`event_date')
		local xtitle "Year-qtr"
		}
		else if "`time'" == "anio_sem" {
		format `time' %th
		local vertical = th(`event_date')
		local xtitle "Year-half"		
		}
		else {
		format `time' %ty
		local vertical = `event_date'
		local xtitle "Year"	
		}
	local number_outcomes: word count `outcomes'
	tsset `time'

	* Create plot for each outcome
	forval i = 1/`number_outcomes' {
		local outcome_var: word `i' of `outcomes'
	    local stub_var: word `i' of `stub_list'
		
		*tssmooth ma `city'_`outcome_var' = `city'_`outcome_var', window(1 1 1) replace
		*tssmooth ma s_`city'_`outcome_var' = s_`city'_`outcome_var', window(1 1 1) replace
		
		qui twoway (line `city'_`outcome_var' `time', lcolor(navy) lwidth(thick)) ///
			   (line s_`city'_`outcome_var' `time', lpattern(dash) lcolor(black)), xtitle("`xtitle'") ///
			   ytitle("`stub_var'") xline(`vertical', lcolor(black) lpattern(dot)) ///
			   legend(label(1 `city_legend') label(2 "Synthetic `city_legend'")) ///
			   title(`stub_var', color(black) size(medium)) ///
			   ylabel(#2) graphregion(color(white)) bgcolor(white) ///
			   name(`city'_`outcome_var'`special_legend', replace)
    }
	
	forval i = 1/`number_outcomes' {
		local outcome_var: word `i' of `outcomes'
		local plots = "`plots' " + "`city'_`outcome_var'`special_legend'"
	}
		
	local plot1: word 1 of `plots' 	
	
	grc1leg `plots', rows(`number_outcomes') legendfrom(`plot1') position(6) ///
		   graphregion(color(white)) title({bf: `city_legend' `special_legend'}, color(black) size(small)) ///
		   name(scm_`city'_`groups_vars'_`time'`special_legend')
end

main_scm
