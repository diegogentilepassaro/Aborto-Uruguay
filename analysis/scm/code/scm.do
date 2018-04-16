clear all
set more off

program main_scm
	do ../../globals.do
    * Definition of research designs
	local add_control_vars = "edad married nbr_people ind_under14 y_hogar"
	local labor_vars   = "trabajo horas_trabajo"
	local educ_vars    = "educ_HS_or_more educ_more_HS"
	local outcome_vars = "`labor_vars' " + "`educ_vars'"
	local labor_stubs  = `" "Employment" "Hours-worked" "'
	local educ_stubs   = `" "High-school" "Some-college" "'
		
	foreach city in rivera salto florida {
	    foreach group_vars in /*educ*/ labor {
			
			foreach special_legend in "" /*"placebo"*/ {
			
				if "`special_legend'" == "placebo" {
				
				    if "`group_vars'" == "labor" {
					    local sample_restr = "keep if hombre == 0 & inrange(edad, 40, 60)"
					}
					else {
					    local sample_restr = "keep if hombre == 0 & inrange(edad, 40, 60)"
					}
				}
				else {
				    if "`group_vars'" == "labor" {
					    local sample_restr = "keep if hombre == 0 & inrange(edad, 16, 45)"
					}
					else {
					    local sample_restr = "keep if hombre == 0 & inrange(edad, 18, 25)"
					}
				}
					
			build_synth_control, outcomes(`outcome_vars') city(`city') time(anio_sem)  ///
				controls(`add_control_vars') special_legend(`special_legend') geo_var(loc_code) ///
				sample_restr(`sample_restr')
				
			/*build_synth_control, outcomes(`outcome_vars') city(`city') time(anio)  ///
				controls(`add_control_vars') special_legend(`special_legend') geo_var(loc_code) ///
				sample_restr(`sample_restr')*/
			
			plot_scm, outcomes(``group_vars'_vars') city(`city') groups_vars(`group_vars') geo_var(loc_code) ///
				time(anio_sem) stub_list(``group_vars'_stubs') special_legend(`special_legend')

			/*plot_scm, outcomes(``group_vars'_vars') city(`city') groups_vars(`group_vars') geo_var(loc_code) ///
				time(anio) stub_list(``group_vars'_stubs') special_legend(`special_legend')*/
		}

	/*grc1leg scm_`city'_`group_vars'_anio_sem scm_`city'_`group_vars'_anio_semplacebo, cols(2) ///
	    legendfrom(scm_`city'_`group_vars'_anio_sem) position(6) ///
	    graphregion(color(white))
	graph display, ysize(6.5) xsize(9.5)
	graph export ../figures/scm_`city'_`group_vars'_anio_sem.pdf, replace

	grc1leg scm_`city'_`group_vars'_anio scm_`city'_`group_vars'_anioplacebo, cols(2) ///
	    legendfrom(scm_`city'_`group_vars'_anio) position(6) ///
	    graphregion(color(white))
	graph display, ysize(6.5) xsize(9.5)
	graph export ../figures/scm_`city'_`group_vars'_anio.pdf, replace*/
	}
	}
end

program build_synth_control
	syntax [if], outcomes(string) controls(string) city(string) geo_var(string) ///
	    time(str) sample_restr(str) [special_legend(string)]

    use "..\..\..\assign_treatment\output\ech_final_98_2016.dta", clear
	if "`geo_var'" == "loc_code" {
        drop treatment_*_s placebo_*_s
    } 
    else {
        drop treatment_*_c placebo_*_c
    }
    `sample_restr'

	* Setup time settings by: qtr, sem, yr
	* Keep if in analysis period and if without implementations in the anlysis period
	if "`time'" == "anio_qtr" {
			local event_date = tq(${q_date_`city'})
			local weight pesotri
			local lag_list `" ${q_lag_list} "' 
			keep if inrange(`time', `event_date' - ${q_scm_pre} ,  `event_date' + ${q_scm_post})
			keep if treatment_`city'==1 | ((qofd(impl_date_dpto) > `event_date' + ${q_scm_post})| mi(impl_date_dpto))
			qui sum `time'	
			local min_year = year(dofq(r(min)))
		}
		else if "`time'" == "anio_sem" {
			local event_date = th(${s_date_`city'})	
			local weight pesosem
			local lag_list `" ${s_lag_list} "'
			keep if inrange(`time', `event_date' - ${s_scm_pre} ,  `event_date' + ${s_scm_post})
			keep if treatment_`city'==1 | ((hofd(impl_date_dpto) > `event_date' + ${s_scm_post})| mi(impl_date_dpto))
			qui sum `time'	
			local min_year = year(dofh(r(min)))
		}
		else {
			local event_date = ${y_date_`city'}	
			local weight pesoan
			local lag_list `" ${y_lag_list} "' 
			keep if inrange(`time', `event_date' - ${y_scm_pre} ,  `event_date' + ${y_scm_post})
			keep if treatment_`city'==1 | ((yofd(impl_date_dpto) > `event_date' + ${y_scm_post})| mi(impl_date_dpto))
			qui sum `time'
			local min_year = r(min)
		}		

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
		
	* Get identifier of treated unit, and collapse data by time and `geo_var'
	qui sum `geo_var' if treatment_`city'==1 | placebo_`city'==1
	local trunit = r(mean)
	replace treatment_`city'=0 if treatment_`city'!=1 //to include all locations, not just the DiD controls
	replace   placebo_`city'=0 if   placebo_`city'!=1 
	collapse (mean) `controls' `control_vars' `outcomes' treatment_`city' `if' [aw = `weight'], by(`time' `geo_var')
		
	* Check the panel is balanced, this is for the synthetic control to work
	xtset `geo_var' `time'
	local num_`time's = r(tmax) - r(tmin) + 1
	bysort `geo_var': gen num_`time' = _N
	keep if num_`time' == `num_`time's'  /*for proper geocodes this should be an assertion*/

	* Check the panel is balanced against missing values
	local n_outcomes: word count `outcomes'
	forval i = 1/`n_outcomes' {
		local outcome_var: word `i' of `outcomes' 
		drop if `outcome_var'==.
	}
	bysort `geo_var': replace num_`time' = _N
	keep if num_`time' == `num_`time's' /*for proper geocodes this should be an assertion*/

	save "../temp/donorpool_`city'_`time'`special_legend'.dta", replace
	
	* Create the synth control for each outcome
	forval i = 1/`n_outcomes' {
		local var: word `i' of `outcomes'
		use "../temp/donorpool_`city'_`time'`special_legend'.dta", clear
		
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
		di " "
		di "*** SCM for `city' `time' `var' ***"
		synth `var' `controls' `control_vars_exp' `lags', ///
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
	save "../temp/controltrends_`city'_`time'_`geo_var'`special_legend'.dta", replace
end

program plot_scm
    syntax, outcomes(string) city(string) time(str) groups_vars(str) geo_var(string) ///
	    stub_list(string) [special_legend(string)]
	
	use "../temp/controltrends_`city'_`time'_`geo_var'`special_legend'.dta", clear

	* Setup time settings by: qtr, sem, yr
    if "`time'" == "anio_qtr" {
	    format `time' %tq 
		local range "if inrange(`time', tq(${q_date_`city'}) - ${q_pre},tq(${q_date_`city'}) + ${q_post}) "
		local vertical = tq(${q_date_`city'}) + 0.5
		local xtitle "Year-qtr"
		}
		else if "`time'" == "anio_sem" {
		format `time' %th
		local range "if inrange(`time', th(${s_date_`city'}) - ${s_pre},th(${s_date_`city'}) + ${s_post}) "
		local vertical = th(${s_date_`city'}) + 0.5
		local xtitle "Year-half"		
		}
		else {
		format `time' %ty
		local range "if inrange(`time', ${y_date_`city'} - ${y_pre}, ${y_date_`city'} + ${y_post}) "
		local vertical = ${y_date_`city'} + 0.5
		local xtitle "Year"	
		}
	local number_outcomes: word count `outcomes'
	tsset `time'
	
	di `vertical'

	* Create plot for each outcome
	forval i = 1/`number_outcomes' {
		local outcome_var: word `i' of `outcomes'
	    local stub_var: word `i' of `stub_list'
		
		tssmooth ma `city'_`outcome_var' = `city'_`outcome_var', window(1 1 0) replace
		tssmooth ma s_`city'_`outcome_var' = s_`city'_`outcome_var', window(1 1 0) replace
		 if "`outcome_var'" == "trabajo" {
			        local ylabel "0.4 (0.1) 0.6"
			    }
			    else if "`outcome_var'" == "horas_trabajo" {
			        local ylabel "12 (8) 28"
			    }
				
		qui twoway (line `city'_`outcome_var' `time' `range', lcolor(navy) lwidth(thick)) ///
			   (line s_`city'_`outcome_var' `time' `range', lpattern(dash) lcolor(black)), xtitle("`xtitle'") ///
			   ytitle("`stub_var'", size(vlarge)) xline(`vertical', lcolor(black) lpattern(dot)) ///
			   legend(label(1 ${legend_`city'}) label(2 "Synthetic `city_legend'")  size(vlarge) width(100) forcesize) ///
			   title(`stub_var', color(black) size(vlarge))  xtitle(, size(vlarge)) ///
			   ylabel(`ylabel', labs(large)) xlabel(#7, labs(large)) graphregion(color(white)) bgcolor(white) ///
			   name(`city'_`outcome_var'`special_legend', replace)
    }
	
	forval i = 1/`number_outcomes' {
		local outcome_var: word `i' of `outcomes'
		local plots = "`plots' " + "`city'_`outcome_var'`special_legend'"
	}
		
	local plot1: word 1 of `plots' 	
	
	qui grc1leg `plots', rows(`number_outcomes') legendfrom(`plot1') position(6) cols(2) ///
		   graphregion(color(white)) title({bf: ${legend_`city'} `special_legend'}, color(black) size(vlarge)) ///
		   name(scm_`city'_`groups_vars'_`time'`special_legend')
    graph display, ysize(5) xsize(12)
	graph export ../output/scm_`city'_`groups_vars'_`time'_`geo_var'`special_legend'.pdf, replace    
end

main_scm
