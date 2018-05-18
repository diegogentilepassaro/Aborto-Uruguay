clear all
set more off

program main
	qui do ../../globals.do
	global controls = "nbr_people ind_under14 edad married y_hogar_alt"

	pooled_births,  num_periods(6) time(anio_sem)

	pooled_es, data(births) time(anio_sem) geo_var(dpto) num_periods(6) int_mvd(int_mvd)
	pooled_es, data(ech)    time(anio_sem) geo_var(dpto) num_periods(6) int_mvd(int_mvd) outcome(trabajo)
	pooled_es, data(ech)    time(anio_sem) geo_var(dpto) num_periods(6) int_mvd(int_mvd) outcome(horas_trabajo)
	pooled_es, data(births) time(anio_sem) geo_var(dpto) num_periods(6) int_mvd(all)
	pooled_es, data(ech)    time(anio_sem) geo_var(dpto) num_periods(6) int_mvd(all) outcome(trabajo)
	pooled_es, data(ech)    time(anio_sem) geo_var(dpto) num_periods(6) int_mvd(all) outcome(horas_trabajo)

	pooled_did, data(ech)    time(anio_sem) geo_var(dpto) num_periods(6) int_mvd(int_mvd) outcome(trabajo)
	pooled_did, data(ech)    time(anio_sem) geo_var(dpto) num_periods(6) int_mvd(int_mvd) outcome(horas_trabajo)
	pooled_did, data(ech)    time(anio_sem) geo_var(dpto) num_periods(6) int_mvd(riv_flo) outcome(trabajo)
	pooled_did, data(ech)    time(anio_sem) geo_var(dpto) num_periods(6) int_mvd(riv_flo) outcome(horas_trabajo)
end

capture program drop assign_impl_date_mvd
program              assign_impl_date_mvd
syntax, dpto_list(str)
	qui sum impl_date_dpto if dpto==1
	replace impl_date_dpto = `r(mean)' if inlist(dpto`dpto_list')
	qui sum impl_date_dpto             if inlist(dpto,1`dpto_list')
	assert `r(sd)'==0
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
	replace t = t + `num_periods' + 1  //to make t>=0 for the event window
	replace t = 0    if t < 0
	replace t = 1000 if t >  2*`num_periods' + 1
	assert !mi(t)
end

capture program drop pooled_births
program              pooled_births
syntax,  num_periods(int) time(str)
	* Merge data
	use ..\..\..\assign_treatment\output\births15.dta, clear
	drop if mi(fecparto)
	drop if inlist(depar,20,99) | inrange(edadm,45,49)

	if "`time'" == "anio_sem" {
		local time_label "Semesters"
		local times "anio anio_sem"
	}
	else {
		local time_label "Years"
		local times "anio"
	}
	
	collapse (count) births=edadm, by(`times' age_min age_max depar dpto impl_date_dpto treatment_rivera treatment_florida)
	isid `time' age_min age_max dpto

	merge m:1 depar age_min age_max anio using ..\..\..\derived\output\population_fertile_age.dta, assert(3)
	gen TFR_agegroup = births/pop

	collapse (sum) TFR = TFR_agegroup, by(`times' dpto impl_date_dpto treatment_rivera treatment_florida depar)
	isid `time' dpto
	replace TFR = 5 * TFR
	lab var TFR "Total Fertility Rate"
	
	* Define treatment var & assign "fake" impl_date to controls
		gen treatment = (treatment_florida==1  |   treatment_rivera==1) ///
				if   !mi(treatment_florida)|!mi(treatment_rivera)
		foreach d in rivera florida {
			qui sum impl_date_dpto             if treatment_`d'==1
			replace impl_date_dpto = `r(mean)' if treatment_`d'==0 
		}
		assign_impl_date_mvd, dpto_list(,3,16,9,10)
		replace treatment = 1 if inlist(dpto,3,16)
		replace treatment = 0 if inlist(dpto,9,10)

	keep if !mi(impl_date_dpto) 
	relative_time, num_periods(`num_periods') time(`time') event_date(impl_date_dpto)

	egen Treatment = mean(TFR) if treatment==1, by(t)
	egen Control   = mean(TFR) if treatment==0, by(t)
	egen tag_t = tag(t) if treatment==1
	egen tag_c = tag(t) if treatment==0
	
	twoway  (connected Treatment t if tag_t & inrange(t,1,13), sort) ///
			(connected Control   t if tag_c & inrange(t,1,13), sort), ///
		graphregion(color(white)) bgcolor(white) ///
		xlabel(1 "-6" 3 "-4" 5 "-2" 7 "0" 9 "2" 11 "4" 13 "6") ///
		xtitle("`time_label' relative to IS implementation") ///
		xline(6.5 7.5, lcolor(black) lpattern(dot)) ytitle(`: var lab TFR')
	graph export ../output/pooled_did_births.pdf, replace
	
	keep if treatment==1 | dpto==1

		egen mean = mean(TFR), by(t)
		lab var mean "`: var lab TFR'"
		egen tag = tag(t)
		qui sum TFR if inrange(t, 1, `num_periods')
		local target_mean = r(mean)

		twoway connected mean t if tag & inrange(t,1,13), sort ///
			graphregion(color(white)) bgcolor(white) ///
			xlabel(1 "-6" 3 "-4" 5 "-2" 7 "0" 9 "2" 11 "4" 13 "6") ///
			xline(6.5 7.5, lcolor(black) lpattern(dot)) ///
			xtitle("`time_label' relative to IS implementation") ///
			yline(`target_mean', lpattern(dashed))
		graph export ../output/pooled_es_births_t.pdf, replace

		egen mean2 = mean(TFR), by(`time')
		lab var mean2 "`: var lab TFR'"
		egen tag2 = tag(`time')

		twoway connected mean2 `time' if tag2 , sort xtitle("`time_label'") ///
			 graphregion(color(white)) bgcolor(white)
		graph export ../output/pooled_es_births_`time'.pdf, replace
end

capture program drop pooled_es
program              pooled_es
syntax, data(str) time(str) geo_var(str) num_periods(int) int_mvd(str) [outcome(str) groups_vars(str) restr(str)]

	if "`data'" == "ech" {
		use  ..\..\..\assign_treatment\output\ech_final_98_2016.dta, clear
		keep if hombre == 0 & inrange(edad, 16, 45)
		if "`outcome'" == "horas_trabajo" {
			keep if trabajo==1
		}
	}
	else {
		/*use ..\..\..\derived\output\population_fertile_age.dta, clear
		keep if inrange(anio,1999,2015)
		collapse (sum) pop, by(depar anio)
		tempfile population
		save `population'*/

		use  ..\..\..\assign_treatment\output\births.dta, clear
		collapse (count) births=edadm (min) impl_date_dpto , by(`time' `geo_var')
		*drop if inlist(depar,20,99)
		*merge m:1 depar anio using `population', assert(3)
		*gen births = births_l/pop*1000
		lab var births "Number of births"
		local outcome births
	}

	if "`int_mvd'" == "int_mvd" {	
		assign_impl_date_mvd, dpto_list(,3,16)	
		keep if !mi(impl_date_dpto) & !inlist(dpto,1)
	}
	else {
		assign_impl_date_mvd, dpto_list(,3,16)
		keep if !mi(impl_date_dpto)  //drop Montevideo
	}

	if "`time'" == "anio_sem" {
		local weight pesosem
		gen post = (`time' >= hofd(impl_date_dpto))
		qui sum `time'
		local min_year = year(dofh(r(min)))
		local time_label "Semesters"
	}
	else {
		local weight pesoan
		gen post = (`time' >= yofd(impl_date_dpto))
		qui sum `time'    
		local min_year = r(min)
	}
	
    if `min_year' < 2001  {
			local control_vars " c98_* "
			}
		else if `min_year' >=2001 & `min_year' < 2006  {
			local control_vars " c98_* c01_* "
			}
		else {
			local control_vars " c98_* c01_* c06_* "
			}
	
	relative_time, num_periods(`num_periods') time(`time') event_date(impl_date_dpto)
	tab t,m
	tab dpto,m
	if "`data'" == "ech" {
		*local all_controls = "`control_vars' ${controls}"
		replace `weight' = int(`weight')
		local pweight = "[pw = `weight']"
	}
	else {
		local all_controls = ""
		local pweight = ""
	}
	if "`outcome'" == "trabajo" {
		local estimation = "logit" // "reg" //
	}
	else {
		local estimation = "reg"
	}
	* Run regression and plot coefficients
	`estimation' `outcome' ib`num_periods'.t i.`time' i.`geo_var'  `all_controls' `pweight', vce(cluster `time')
	* Coef plot
	coefplot, vertical baselevels graphregion(color(white)) bgcolor(white) ///
		drop(_cons 0.t 1000.t *.`time' *.`geo_var'  `all_controls') ///
		xtitle("`time_label' relative to IS implementation") ytitle(`: var lab `outcome'') ///
		xlabel(1 "-6" 3 "-4" 5 "-2" 7 "0" 9 "2" 11 "4" 13 "6") xline(6.5 7.5, lcolor(black) lpattern(dot))
	graph export ../output/pooled_es_`outcome'_`time'_`geo_var'_`int_mvd'.pdf, replace
	* Coef plot with shift
	qui sum `outcome' if inrange(t, 1, `num_periods')
	local target_mean = r(mean)
	preserve
	    coefplot, omitted vertical baselevels gen ///
			drop(_cons 0.t 1000.t *.`time' *.`geo_var' `control_vars' ${controls})
	    qui sum __b
	    local coef_mean = r(mean)
	restore 
	local yshift = `target_mean' - `coef_mean'
	coefplot, vertical baselevels graphregion(color(white)) bgcolor(white) ///
		drop(_cons 0.t 1000.t *.`time' *.`geo_var' `all_controls') ///
	    transform(*= "@ + `yshift'") yline(`target_mean', lpattern(dashed)) ///
		xtitle("`time_label' relative to IS implementation") ytitle(`: var lab `outcome'') ///
		xlabel(1 "-6" 3 "-4" 5 "-2" 7 "0" 9 "2" 11 "4" 13 "6") xline(6.5 7.5, lcolor(black) lpattern(dot))
		
	graph export ../output/pooled_es_shift_`outcome'_`time'_`geo_var'_`int_mvd'.pdf, replace
end

capture program drop pooled_did
program              pooled_did
syntax, data(str) time(str) geo_var(str) num_periods(int) int_mvd(str) [outcome(str) groups_vars(str) restr(str)]

	if "`data'" == "ech" {
		use  ..\..\..\assign_treatment\output\ech_final_98_2016.dta, clear
		keep if hombre == 0 & inrange(edad, 16, 45) & inrange(horas_trabajo,0,100)
		if "`outcome'" == "horas_trabajo" {
			keep if trabajo==1
		}
		tab trabajo,m
	}
	else {
		use  ..\..\..\assign_treatment\output\births.dta, clear
		collapse (count) births=edadm (min) impl_date_dpto , by(`time' `geo_var')
		lab var births "Number of births"
		local outcome births
	}

	gen treatment = (treatment_florida_c==1  |   treatment_rivera_c==1) ///
			if   !mi(treatment_florida_c)   |!mi(treatment_rivera_c)
	foreach city in rivera florida {
		qui sum impl_date_dpto             if treatment_`city'_c==1
		replace impl_date_dpto = `r(mean)' if treatment_`city'_c==0 
	}

	if "`int_mvd'" == "int_mvd" {
		assign_impl_date_mvd, dpto_list(,3,16,9,10)
		replace treatment = 1 if inlist(dpto,3,16)
		replace treatment = 0 if inlist(dpto,9,10)
		keep if !mi(impl_date_dpto) & !inlist(dpto,1) //drop Montevideo
	}
	else {
		keep if !mi(impl_date_dpto) & !inlist(dpto,1,3,16) //drop Montevideo, San Jose, and Canelones
	}

	//assert !mi(treatment)
	
	
	if "`time'" == "anio_qtr" {
		local weight pesotri
		gen post = (`time' >= qofd(impl_date_dpto))
		qui sum `time'
		local min_year = year(dofq(r(min)))
		local time_label "Quarters"
	}
	else if "`time'" == "anio_sem" {
		local weight pesosem
		gen post = (`time' >= hofd(impl_date_dpto))
		qui sum `time'
		local min_year = year(dofh(r(min)))
		local time_label "Semesters"
	}
	else {
		local weight pesoan
		gen post = (`time' >= yofd(impl_date_dpto))
		qui sum `time'    
		local min_year = r(min)
	}
	
	if `min_year' < 2001  {
			local control_vars " c98_* "
			}
		else if `min_year' >=2001 & `min_year' < 2006  {
			local control_vars " c98_* c01_* "
			}
		else {
			local control_vars " c98_* c01_* c06_* "
			}
	
	relative_time, num_periods(`num_periods') time(`time') event_date(impl_date_dpto)
	replace t = t+1 if t<1000
	tab t,m
	tab dpto,m
	if "`data'" == "ech" {
		local all_controls = "`control_vars' ${controls}"
		replace `weight' = int(`weight')
		local pweight = "[pw = `weight']"
	}
	else {
		local all_controls = ""
		local pweight = ""
	}
	if "`outcome'" == "trabajo" {
		local estimation = "logit" // "reg" //
	}
	else {
		local estimation = "reg"
	}
	local omitted = `num_periods'+1 //tr_t = treatment*t
	* Run regression and plot coefficients
	`estimation' `outcome' ib`omitted'.t##i.treatment i.`time' i.`geo_var'  `all_controls' `pweight', vce(cluster `time')
	* Coef plot
	coefplot, vertical baselevels graphregion(color(white)) bgcolor(white) ///
		drop(_cons *.t 1.t#1.treatment 1000.t#1.treatment 1.treatment 0.treatment *.`time' *.`geo_var'  `all_controls') ///
		xtitle("`time_label' relative to IS implementation") ytitle(`: var lab `outcome'') ///
		xlabel(1 "-6" 3 "-4" 5 "-2" 7 "0" 9 "2" 11 "4" 13 "6") xline(6.5 7.5, lcolor(black) lpattern(dot))
	graph export ../output/pooled_did_`outcome'_`time'_`geo_var'_`int_mvd'.pdf, replace
	* Coef plot with shift
	qui sum `outcome' if inrange(t, 0, `num_periods' - 1)
	local target_mean = r(mean)
	preserve
	    coefplot, omitted vertical baselevels gen ///
			drop(_cons 0.t 1000.t *.`time' *.`geo_var' `control_vars' ${controls})
	    qui sum __b
	    local coef_mean = r(mean)
	restore 
	local yshift = `target_mean' - `coef_mean'
	coefplot, vertical baselevels graphregion(color(white)) bgcolor(white) ///
		drop(_cons 0.t 1000.t *.`time' *.`geo_var' `all_controls') ///
	    transform(*= "@ + `yshift'") yline(`target_mean', lpattern(dashed)) ///
		xtitle("`time_label' relative to IS implementation") ytitle(`: var lab `outcome'') ///
		xlabel(1 "-6" 3 "-4" 5 "-2" 7 "0" 9 "2" 11 "4" 13 "6") xline(6.5 7.5, lcolor(black) lpattern(dot))
		
	graph export ../output/pooled_did_shift_`outcome'_`time'_`geo_var'_`int_mvd'.pdf, replace
end

main

