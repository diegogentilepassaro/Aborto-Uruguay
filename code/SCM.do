clear all
set more off
/*
program scm

	* Create donor pools for each Research Design (city)
	gen dp_mvd_city = 1
	gen geocode = _n

    local control_vars  = "i.anio_qtr i.dpto edad married y_hogar"
	local outcome_vars	= "trabajo horas_trabajo"
		
	build_synth_control, data("..\base\ech_final_98_2016.dta") sample(asec) ///
	    outcomes(`outcome_vars') controls(`control_vars') city(mvd_city) tline(2002q1)

end

program build_synth_control
	syntax [if], data(string) outcomes(string) controls(string) city(string) sample(string) tline(string) [stub(string)]
    // tr_period(int)
	use `data', clear
	*/
	
	use "..\base\ech_final_98_2016.dta", clear
	gen dp_mvd_city = 1
	egen geocode = group(loc dpto)
	local city mvd_city
	local tline 2002q1
	local outcomes	= "trabajo"
	local controls  = "edad married y_hogar"
    
	//preserve
	
		drop if dp_`city'==0
		keep if inrange(anio_qtr, tq(`tline') - 12,tq(`tline') + 12)
		
		* NOTE: we need a unique geo code for each place, at the finest level, for now I'm calling it geocode
		qui sum geocode if treatment_`city'==1
		local trunit = r(mean)
		qui sum anio_qtr  if  tq(`tline'), det
		local tr_period = r(p50)
		gen anio_qtr_2 = qofd(dofq(anio_qtr))
		drop anio_qtr
		rename anio_qtr_2 anio_qtr

		collapse (mean) `controls' `outcomes' treatment_`city' `if' [aw = pesotri], by(anio_qtr geocode)
		
		* Check the panel is balanced, this is for the synthetic control to work
		xtset geocode anio_qtr
		local num_anio_qtrs = r(tmax) - r(tmin) + 1
		di `num_anio_qtrs'
		bysort geocode: gen num_anio_qtr = _N
		keep if num_anio_qtr == `num_anio_qtrs'  /*for proper geocodes this should be an assertion*/

		* Check the panel is balanced against missing values
		local n_outcomes: word count `outcomes'
		forval i = 1/`n_outcomes' {
			local outcome_var: word `i' of `outcomes' 
			drop if `outcome_var'==.
		}
		bysort geocode: replace num_anio_qtr = _N
		keep if num_anio_qtr == `num_anio_qtrs' /*for proper geocodes this should be an assertion*/

		save "../temp/`sample'_donorpool_`city'`stub'.dta", replace
		
		* Create the synth control for each outcome
		forval i = 1/`n_outcomes' {
			use "../temp/`sample'_donorpool_`city'`stub'.dta", clear
			
			local var: word `i' of `outcomes'
			/*local lag1 = `tr_period' - 10
			local lag2 = `tr_period' - 8
			local lag3 = `tr_period' - 6
			local lag4 = `tr_period' - 4
			local lag5 = `tr_period' - 2
			local lags = "`var'(`lag1') `var'(`lag2') `var'(`lag3') `var'(`lag4') `var'(`lag5')"*/
			
			synth `var' `controls' `lags', ///
				trunit(`trunit') trperiod(`tr_period') figure ///
				keep("../temp/`sample'_synth_`city'_`var'`stub'.dta", replace)
		}	
			

			/*use "../temp/`sample'_synth_`city'_`var'`stub'.dta", clear
			rename (_Co_Number _time _Y_treated _Y_synthetic) ///
				(geocode anio_qtr `city'_`var' synthetic_`city'_`var')

			drop if anio_qtr==.
			drop geocode _W_Weight

			save "../temp/`sample'_synth_`city'_`var'`stub'.dta", replace
		}

		local n_outcomes: word count `outcomes'
		local outcome_var: word 1 of `outcomes' 
		use "../temp/`sample'_synth_`city'_`outcome_var'`stub'", clear

		forval i = 2/`n_outcomes' {
			local outcome_var: word `i' of `outcomes' 

			merge 1:1 anio_qtr using "../temp/`sample'_synth_`city'_`outcome_var'`stub'", nogen
		}
		save "../derived_`sample'/controltrends_`city'`stub'.dta", replace

	restore
	
end*/

