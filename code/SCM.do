clear all
set more off

program main_scm
    local control_vars  = "edad married cantidad_personas hay_menores y_hogar"
	local outcome_vars	= "trabajo horas_trabajo"
	local stub_list = `" "Employment" "Hours-worked" "'
	
	use "..\base\ech_final_98_2016.dta", clear
	drop if hombre == 1
	keep if inrange(edad, 14, 45)
	
	build_synth_control, outcomes(`outcome_vars') controls(`control_vars') ///
	    city(mvd) event_date(2002q1)
	
	build_synth_control, outcomes(`outcome_vars') controls(`control_vars') ///
	    city(rivera) event_date(2010q3) restr((dpto == 1 | loc_code == 330020 | loc_code == 1630020))
		
	build_synth_control, outcomes(`outcome_vars') controls(`control_vars') ///
	    city(salto) event_date(2013q1)
    
	plot_scm, outcomes(`outcome_vars') city(mvd) city_legend(Montevideo) event_date(2002q1) ///
	    stub_list(`stub_list')
	plot_scm, outcomes(`outcome_vars') city(rivera) city_legend(Rivera) event_date(2010q3) ///
	    stub_list(`stub_list')
	plot_scm, outcomes(`outcome_vars') city(salto) city_legend(Salto) event_date(2013q1) ///
	    stub_list(`stub_list')
end

program build_synth_control
	syntax [if], outcomes(string) controls(string) city(string) event_date(string) ///
	    [special(string) restr(string)]
		
    preserve
	
	keep if inrange(anio_qtr, tq(`event_date') - 12,tq(`event_date') + 12) 
	
	cap drop if `restr'
	
	qui sum loc_code if treatment_`city'==1
	local trunit = r(mean)
	qui sum anio_qtr  if  anio_qtr == tq(`event_date'), det
	local event_date = r(mean)

	collapse (mean) `controls' `outcomes' treatment_`city' `if' [aw = pesotri], by(anio_qtr loc_code)
	
	* Check the panel is balanced, this is for the synthetic control to work
	xtset loc_code anio_qtr
	local num_anio_qtrs = r(tmax) - r(tmin) + 1
	bysort loc_code: gen num_anio_qtr = _N
	keep if num_anio_qtr == `num_anio_qtrs'  /*for proper geocodes this should be an assertion*/

	* Check the panel is balanced against missing values
	local n_outcomes: word count `outcomes'
	forval i = 1/`n_outcomes' {
		local outcome_var: word `i' of `outcomes' 
		drop if `outcome_var'==.
	}
	bysort loc_code: replace num_anio_qtr = _N
	keep if num_anio_qtr == `num_anio_qtrs' /*for proper geocodes this should be an assertion*/

	save "../temp/donorpool_`city'`special'.dta", replace
	
	* Create the synth control for each outcome
	forval i = 1/`n_outcomes' {
		use "../temp/donorpool_`city'`special'.dta", clear
		
		local var: word `i' of `outcomes'
		/*local lag1 = `event_date' - 10
		local lag2 = `event_date' - 8
		local lag3 = `event_date' - 6
		local lag4 = `event_date' - 4
		local lag5 = `event_date' - 2
		local lags = "`var'(`lag1') `var'(`lag2') `var'(`lag3') `var'(`lag4') `var'(`lag5')"*/
		
		synth `var' `controls' `lags', ///
			trunit(`trunit') trperiod(`event_date') figure ///
			keep("../temp/synth_`city'_`var'`special'.dta", replace)	

		use "../temp/synth_`city'_`var'`special'.dta", clear
		rename (_Co_Number _time _Y_treated _Y_synthetic) ///
			(geocode anio_qtr `city'_`var'`special' synthetic_`city'_`var'`special')

		drop if anio_qtr==.
		drop geocode _W_Weight

		save "../temp/synth_`city'_`var'`special'.dta", replace
	}

	local outcome_var: word 1 of `outcomes' 
	use "../temp/synth_`city'_`outcome_var'`special'", clear

	forval i = 2/`n_outcomes' {
		local outcome_var: word `i' of `outcomes' 

		merge 1:1 anio_qtr using "../temp/synth_`city'_`outcome_var'`special'", nogen
	}
	save "../derived/controltrends_`city'`special'.dta", replace
	
	restore
end

program plot_scm
    syntax, outcomes(string) city(string) city_legend(string) event_date(string) ///
	    stub_list(string) [special(string) special_legend(string)]
	
	use "../derived/controltrends_`city'`special'.dta", clear
	
	format anio_qtr %tq
	
	local number_outcomes: word count `outcomes'
    local vertical = tq(`event_date')
	
	tsset anio_qtr

	
	forval i = 1/`number_outcomes' {
		local outcome_var: word `i' of `outcomes'
	    local stub_var: word `i' of `stub_list'
		
		tssmooth ma `city'_`outcome_var' = `city'_`outcome_var', window(1 1 1) replace
		tssmooth ma synthetic_`city'_`outcome_var' = synthetic_`city'_`outcome_var', window(1 1 1) replace
		
		qui twoway (line `city'_`outcome_var' anio_qtr, lcolor(navy) lwidth(thick)) ///
			   (line synthetic_`city'_`outcome_var' anio_qtr, lpattern(dash) lcolor(black)), xtitle("Year-qtr") ///
			   ytitle("`stub_var'") xline(`vertical', lcolor(black) lpattern(dot)) ///
			   legend(label(1 `city_legend') label(2 "Synthetic `city_legend'")) ///
			   title(`stub_var', color(black) size(medium)) ///
			   ylabel(#2) graphregion(color(white)) bgcolor(white) name(`city'_trend_`outcome_var'`special', replace)
    }
	
	forval i = 1/`number_outcomes' {
		local outcome_var: word `i' of `outcomes'
		local plots = "`plots' " + "`city'_trend_`outcome_var'`special'"
	}
		
	local plot1: word 1 of `plots' 	
	
	grc1leg `plots', rows(`number_outcomes') legendfrom(`plot1') position(6) /// /* cols(1) or cols(3) */
		   graphregion(color(white)) title({bf: `city_legend' `special_legend'}, color(black) size(small))
	*graph display, ysize(8.5) xsize(6.5)
	graph export ../figures/scm_`city'`special'.png, replace
end

main_scm
