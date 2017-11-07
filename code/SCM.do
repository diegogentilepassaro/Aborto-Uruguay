clear all
set more off

program main_scm
    local control_vars  = "edad married cantidad_personas hay_menores y_hogar"
	local outcome_vars	= "trabajo horas_trabajo educ_HS_or_more"
	local stub_list = `" "Employment" "Hours-worked" "High-school" "'
	
	use "..\base\ech_final_98_2016.dta", clear
	drop if hombre == 1
	keep if inrange(edad, 14, 40)
	
	local date_is_chpr "2002q1"
	local date_rivera "2010q3"
	local date_ive "2013q1"
	
	local sem_date_is_chpr "2002h1"
	local sem_date_rivera "2010h2"
	local sem_date_ive "2013h1"
	
	build_synth_control, outcomes(`outcome_vars') controls(`control_vars') ///
	    city(mvd) event_date(`date_is_chpr') time(anio_qtr) weight(pesotri)
	
	build_synth_control, outcomes(`outcome_vars') controls(`control_vars') ///
	    city(mvd) event_date(`sem_date_is_chpr') time(anio_sem) weight(pesosem)

	build_synth_control, outcomes(`outcome_vars') controls(`control_vars') ///
	    city(rivera) event_date(`date_rivera') time(anio_qtr) weight(pesotri) ///
		restr((dpto == 1 | loc_code == 330020 | loc_code == 1630020))
		
	build_synth_control, outcomes(`outcome_vars') controls(`control_vars') ///
	    city(rivera) event_date(`sem_date_rivera') time(anio_sem) weight(pesosem) ///
		restr((dpto == 1 | loc_code == 330020 | loc_code == 1630020))

	build_synth_control, outcomes(`outcome_vars') controls(`control_vars') ///
	    city(salto) event_date(`date_ive') time(anio_qtr) weight(pesotri)
		
	build_synth_control, outcomes(`outcome_vars') controls(`control_vars') ///
	    city(salto) event_date(`sem_date_ive') time(anio_sem) weight(pesosem)
		
    plot_scm, outcomes(`outcome_vars') city(mvd) city_legend(Montevideo) ///
	    event_date(`date_is_chpr') time(anio_qtr) stub_list(`stub_list')

	plot_scm, outcomes(`outcome_vars') city(mvd) city_legend(Montevideo) ///
	    event_date(`sem_date_is_chpr') time(anio_sem) stub_list(`stub_list') 

	plot_scm, outcomes(`outcome_vars') city(rivera) city_legend(Rivera) ///
	    event_date(`date_rivera') time(anio_qtr) stub_list(`stub_list')

    plot_scm, outcomes(`outcome_vars') city(rivera) city_legend(Rivera) ///
	    event_date(`sem_date_rivera') time(anio_sem) stub_list(`stub_list')

    plot_scm, outcomes(`outcome_vars') city(salto) city_legend(Salto) ///
	    event_date(`date_ive') time(anio_qtr) stub_list(`stub_list')

    plot_scm, outcomes(`outcome_vars') city(salto) city_legend(Salto) ///
	    event_date(`sem_date_ive') time(anio_sem) stub_list(`stub_list')
end

program build_synth_control
	syntax [if], outcomes(string) controls(string) city(string) event_date(string) ///
	    time(str) weight(str) [special(string) restr(string)]
		
    preserve
	
	if "`time'" == "anio_qtr" {
		local range "if inrange(`time', tq(`event_date') - 12,tq(`event_date') + 12) "
	    qui sum `time' `range'	
		local min_year = year(dofq(r(min)))
		qui sum `time'  if  `time' == tq(`event_date')
		}
		else {
		local range "if inrange(`time', th(`event_date') - 6,th(`event_date') + 6) "
	    qui sum `time' `range'	
		local min_year = year(dofh(r(min)))
		qui sum `time'  if  `time' == th(`event_date')		
		}
	local event_date = r(mean)		
		
	keep `range'
	
	cap drop if `restr'
	
	qui sum loc_code if treatment_`city'==1
	local trunit = r(mean)
	
	if `min_year' < 2001  {
		local control_vars " c98_* "
		}
	else if `min_year' >=2001 & `min_year' < 2006  {
		local control_vars " c98_* c01_* "
		}
	else {
		local control_vars " c98_* c01_* c06_* "
		}
	
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

	save "../base/donorpool_`city'_`time'`special'.dta", replace
	
	* Create the synth control for each outcome
	forval i = 1/`n_outcomes' {
		use "../base/donorpool_`city'_`time'`special'.dta", clear
		
		local var: word `i' of `outcomes'
		local lag1 = `event_date' - 1
		local lag2 = `event_date' - 2
		local lag3 = `event_date' - 3
		local lag4 = `event_date' - 4
		local lag5 = `event_date' - 5
		local lags = "`var'(`lag1') `var'(`lag2') `var'(`lag3') `var'(`lag4') `var'(`lag5')"
		
		desc `control_vars' , f varlist
		local control_vars_exp `r(varlist)'
		
		synth `var' `controls' `control_vars_exp' `lags', ///
			trunit(`trunit') trperiod(`event_date') figure ///
			keep("../temp/synth_`city'_`var'`special'.dta", replace)	

		use "../temp/synth_`city'_`var'`special'.dta", clear
		rename (_Co_Number _time _Y_treated _Y_synthetic) ///
			(geocode `time' `city'_`var'`special' synthetic_`city'_`var'`special')

		drop if `time'==.
		drop geocode _W_Weight

		save "../temp/synth_`city'_`var'`special'.dta", replace
	}

	local outcome_var: word 1 of `outcomes' 
	use "../temp/synth_`city'_`outcome_var'`special'", clear

	forval i = 2/`n_outcomes' {
		local outcome_var: word `i' of `outcomes' 

		merge 1:1 `time' using "../temp/synth_`city'_`outcome_var'`special'", nogen
	}
	save "../derived/controltrends_`city'_`time'`special'.dta", replace
	
	restore
end

program plot_scm
    syntax, outcomes(string) city(string) city_legend(string) event_date(string) ///
	    stub_list(string) time(str) [special(string) special_legend(string)]
	
	use "../derived/controltrends_`city'_`time'`special'.dta", clear

    if "`time'" == "anio_qtr" {
	    format `time' %tq 
		local vertical = tq(`event_date')
		local xtitle "Year-qtr"
		}
		else {
		format `time' %th
		local vertical = th(`event_date')
		local xtitle "Year-half"		
		}
	
	local number_outcomes: word count `outcomes'
	
	tsset `time'

	forval i = 1/`number_outcomes' {
		local outcome_var: word `i' of `outcomes'
	    local stub_var: word `i' of `stub_list'
		
		tssmooth ma `city'_`outcome_var' = `city'_`outcome_var', window(1 1 1) replace
		tssmooth ma synthetic_`city'_`outcome_var' = synthetic_`city'_`outcome_var', window(1 1 1) replace
		
		qui twoway (line `city'_`outcome_var' `time', lcolor(navy) lwidth(thick)) ///
			   (line synthetic_`city'_`outcome_var' `time', lpattern(dash) lcolor(black)), xtitle("`xtitle'") ///
			   ytitle("`stub_var'") xline(`vertical', lcolor(black) lpattern(dot)) ///
			   legend(label(1 `city_legend') label(2 "Synthetic `city_legend'")) ///
			   title(`stub_var', color(black) size(medium)) ///
			   ylabel(#2) graphregion(color(white)) bgcolor(white) ///
			   name(`city'_trend_`outcome_var'`special', replace)
    }
	
	forval i = 1/`number_outcomes' {
		local outcome_var: word `i' of `outcomes'
		local plots = "`plots' " + "`city'_trend_`outcome_var'`special'"
	}
		
	local plot1: word 1 of `plots' 	
	
	grc1leg `plots', rows(`number_outcomes') legendfrom(`plot1') position(6) /// /* cols(1) or cols(3) */
		   graphregion(color(white)) title({bf: `city_legend' `special_legend'}, color(black) size(small))
	graph display, ysize(8.5) xsize(6.5)
	graph export ../figures/scm_`city'_`time'`special'.png, replace
end

main_scm
