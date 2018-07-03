clear all
set more off

program main
	qui do ../../globals.do
	global controls = "nbr_people ind_under14 edad married poor"
	local labor_vars   = "trabajo horas_trabajo work_part_time"

	pooled_coefplot, data(births) time(anio_sem) num_periods(6) 
	pooled_TFR_mean, time(anio_sem) num_periods(6)
	pooled_coefplot, data(ech)    time(anio_sem) num_periods(6) outcomes(`labor_vars')
end

capture program drop relative_time
program              relative_time
syntax, num_periods(int) time(str) event_date(str)
	if "`time'" == "anio_qtr" { //+1 since impl_date marks beginning of post
		gen t = `time' - qofd(`event_date')
	}
	else if "`time'" == "anio_sem" {
		gen t = `time' - hofd(`event_date')
	}
	else {
		gen t = `time' - yofd(`event_date')
	}
	replace t = t + `num_periods' + 1  //t>=0. t>0 for the event window (1 is -6, 13 is 6)
	replace t = 0    if t < 0
	replace t = 1000 if t >  2*`num_periods' + 1
	assert !mi(t)
	tab t,m
	replace t = t+1 if t<1000 //t>=1: hence 1 groups all pre-periods before the event window
	tab t,m
end

program compute_TFR
syntax, time(str)
	use ..\..\..\assign_treatment\output\births15.dta, clear
	drop if inrange(edad,45,49)

	if "`time'" == "anio_sem" {
		local time_label "Semesters"
		local times "anio anio_sem"
	}
	else {
		local time_label "Years"
		local times "anio"
	}
	keep if !mi(treatment) | dpto==1
	collapse (count) births=edad, by(`times' age_min age_max depar dpto impl_date_dpto treatment)
	isid `time' age_min age_max dpto

	merge m:1 depar age_min age_max anio using ..\..\..\derived\output\population_fertile_age.dta, keep(3)
	gen TFR_agegroup = births/pop

	collapse (sum) TFR = TFR_agegroup, by(`times' dpto impl_date_dpto treatment depar)
	isid `time' dpto
	replace TFR = 5 * TFR
	lab var TFR "Total Fertility Rate"
	keep `time' dpto TFR
	save ../temp/TFR_`time'.dta, replace
end

capture program drop pooled_TFR_mean
program              pooled_TFR_mean
syntax, time(str) num_periods(int)
	
	use ../temp/plots_sample_births.dta, clear
	if "`time'" == "anio_sem" {
		local time_label "Semesters"
	}
	else {
		local time_label "Years"
	}
	keep if !mi(impl_date_dpto) 
	* Mean TFR: DiD 
	egen Treatment = mean(TFR) if treatment==1, by(t)
	egen Control   = mean(TFR) if treatment==0, by(t)
	egen tag_T = tag(t) if treatment==1
	egen tag_C = tag(t) if treatment==0
	
	twoway  (connected Treatment t if tag_T & inrange(t,2,14), sort) ///
			(connected Control   t if tag_C & inrange(t,2,14), sort), ///
		graphregion(color(white)) bgcolor(white) ///
		xlabel(2 "-6" 4 "-4" 6 "-2" 8 "0" 10 "2" 12 "4" 14 "6") ///
		xtitle("`time_label' relative to IS implementation") ///
		xline(7.5 8.5, lcolor(black) lpattern(dot)) ytitle(`: var lab TFR')
	graph export ../output/pooled_did_TFR_`time'_meanTFR.pdf, replace	
	* Mean TFR: ES and trend
	keep if treatment==1 | dpto==1
	egen mean_t = mean(TFR), by(t)
	lab var mean_t "`: var lab TFR'"
	egen tag_t = tag(t)
	qui sum TFR if inrange(t, 2, `num_periods'+1)
	local target_mean = r(mean)
		twoway connected mean_t t if tag_t & inrange(t,2,14), sort ///
			graphregion(color(white)) bgcolor(white) ///
			xlabel(2 "-6" 4 "-4" 6 "-2" 8 "0" 10 "2" 12 "4" 14 "6") ///
			xline(7.5 8.5, lcolor(black) lpattern(dot)) ///
			xtitle("`time_label' relative to IS implementation") ///
			yline(`target_mean', lpattern(dashed))
		graph export ../output/pooled_es_TFR_`time'_meanTFR.pdf, replace
	egen mean_time = mean(TFR), by(`time')
	lab var mean_time "`: var lab TFR'"
	egen tag_time = tag(`time')
		twoway connected mean_time `time' if tag_time , sort xtitle("`time_label'") ///
			 graphregion(color(white)) bgcolor(white)
		graph export ../output/pooled_trend_TFR_`time'.pdf, replace
end

capture program drop pooled_coefplot
program              pooled_coefplot
syntax, data(str) time(str) num_periods(int) [outcomes(str) groups_vars(str) restr(str)]

	if "`data'" == "ech" {
		use  ..\..\..\assign_treatment\output\ech_final_98_2016.dta, clear
		keep if hombre == 0 & inrange(horas_trabajo,0,100) //& inrange(edad, 16, 45)
		local all_controls = "c98_* ${controls}"
	}
	else {
		compute_TFR, time(`time')
		use  ..\..\..\assign_treatment\output\births.dta, clear
		keep if (!mi(treatment)|dpto==1) & age_fertile==1
		save ../temp/plots_sample_births_ind.dta, replace
		collapse (count) births=edad (min) impl_date_dpto , by(`time' dpto treatment)
		merge 1:1 dpto `time' using ..\temp\TFR_`time'.dta, assert(3) nogen
		gen age_fertile = 1
		lab var births "Number of births"
		local outcomes = "births TFR"
		local all_controls = ""
		tab dpto
	}
	relative_time, num_periods(`num_periods') time(`time') event_date(impl_date_dpto)
	local omitted = `num_periods'+1 //tr_t = treatment*t
	di "Omitted period: -1 (prior to implementation) or t=`omitted'."
	/*relative_time, num_periods(`num_periods') time(`time') event_date(impl_date_dpto)
	tab t,m
	tab dpto,m*/

	if "`time'" == "anio_sem" {
		local weight pesosem
		gen post = (`time' >= hofd(impl_date_dpto))
		local time_label "Semesters relative to IS implementation"
	}
	else {
		local weight pesoan
		gen post = (`time' >= yofd(impl_date_dpto))
		local time_label "Years relative to IS implementation"
	}
	if "`data'" == "ech" {
		replace `weight' = int(`weight')
		local pweight = "[pw = `weight']"
	}
	else {
		local pweight = ""
	}
	
	save ../temp/plots_sample_`data'.dta, replace

	local n_outcomes: word count `outcomes'
    forval i = 1/`n_outcomes' {
        local outcome: word `i' of `outcomes'

        use ../temp/plots_sample_`data'.dta, clear
		
		if "`outcome'" == "horas_trabajo" {
            keep if trabajo==1
        }
		if inlist("`outcome'","trabajo","work_part_time") {
			local estimation = "logit" // "reg" //
		}
		else {
			local estimation = "reg"
		}

		local ES_subsample  = " if (treatment==1 | dpto==1) & age_fertile==1 "
		local DiD_subsample = " if !mi(treatment)           & age_fertile==1 "
		local coefplot_opts = " vertical baselevels graphregion(color(white)) bgcolor(white) " + ///
							  " xline(6.5 7.5, lcolor(black) lpattern(dot))	ytitle(`: var lab `outcome'') "
		
		* ES: run main regression and plot coefficients
		`estimation' `outcome' ib`omitted'.t i.`time' i.dpto  ///
			`ES_subsample' `pweight', vce(cluster `time')
			* Coef plot
			coefplot, `coefplot_opts' xtitle("`time_label'") ///
				drop(_cons 1.t 1000.t *.`time' *.dpto  `all_controls') ///
				xlabel(1 "-6" 3 "-4" 5 "-2" 7 "0" 9 "2" 11 "4" 13 "6") 
			graph export ../output/pooled_es_`outcome'_`time'.pdf, replace
			* Coef plot with shift
			qui sum `outcome' if inrange(t, 1, `num_periods')
			local target_mean = r(mean)
			preserve
			    coefplot, omitted vertical baselevels gen ///
					drop(_cons 1.t 1000.t *.`time' *.dpto `all_controls')
			    qui sum __b
			    local coef_mean = r(mean)
			restore 
			local yshift = `target_mean' - `coef_mean'
			coefplot, `coefplot_opts' xtitle("`time_label'") ///
				drop(_cons 1.t 1000.t *.`time' *.dpto `all_controls') ///
			    transform(*= "@ + `yshift'") yline(`target_mean', lpattern(dashed)) ///
				xlabel(1 "-6" 3 "-4" 5 "-2" 7 "0" 9 "2" 11 "4" 13 "6") 					
			graph export ../output/pooled_es_shift_`outcome'_`time'.pdf, replace
		
		* DiD: run main regression and plot coefficientss
		`estimation' `outcome' ib`omitted'.t##i.treatment i.`time' i.dpto  `all_controls' ///
			`DiD_subsample' `pweight', vce(cluster `time')
			* Coef plot
			coefplot, `coefplot_opts' xtitle("`time_label'") ///
				drop(_cons *.t 1.t#1.treatment 1000.t#1.treatment 1.treatment 0.treatment *.`time' *.dpto  `all_controls') ///
				xlabel(1 "-6" 3 "-4" 5 "-2" 7 "0" 9 "2" 11 "4" 13 "6") 
			graph export ../output/pooled_did_`outcome'_`time'.pdf, replace
			* Coef plot with shift
			qui sum `outcome' if inrange(t, 0, `num_periods' - 1)
			local target_mean = r(mean)
			preserve
			    coefplot, omitted vertical baselevels gen ///
					drop(_cons *.t 1.t#1.treatment 1000.t#1.treatment 1.treatment 0.treatment *.`time' *.dpto `control_vars' ${controls})
			    qui sum __b
			    local coef_mean = r(mean)
			restore 
			local yshift = `target_mean' - `coef_mean'
			coefplot, `coefplot_opts' xtitle("`time_label'") ///
				drop(_cons *.t 1.t#1.treatment 1000.t#1.treatment 1.treatment 0.treatment *.`time' *.dpto `all_controls') ///
			    transform(*= "@ + `yshift'") yline(`target_mean', lpattern(dashed)) ///
				xlabel(1 "-6" 3 "-4" 5 "-2" 7 "0" 9 "2" 11 "4" 13 "6") 				
			graph export ../output/pooled_did_shift_`outcome'_`time'.pdf, replace
	}
end

main

