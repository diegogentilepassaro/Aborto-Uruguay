clear all
set more off

program main
	qui do ../../globals.do
	global controls = "nbr_people ind_under14 edad married y_hogar_alt"

	pooled_es_births, time(anio_sem) geo_var(dpto) num_periods(6)
	pooled_es_ech,    time(anio_sem) geo_var(loc_code) num_periods(6) outcome(trabajo)
	pooled_es_ech,    time(anio_sem) geo_var(loc_code) num_periods(6) outcome(horas_trabajo)
end

capture program drop relative_months
program              relative_months
syntax, num_periods(int) time(str) event_date(str)
	if "`time'" == "anio_qtr" {
		gen t = `time' - qofd(`event_date')  if !mi(`event_date')
	}
	else if "`time'" == "anio_sem" {
		gen t = `time' - hofd(`event_date')  if !mi(`event_date')
	}
	else {
		gen t = `time' - yofd(`event_date')  if !mi(`event_date')
	}
	replace t = t + `num_periods'            if !mi(`event_date') //to make t>=0 for the event window
	replace t = 0    if t < 0                 |  mi(`event_date')
	replace t = 1000 if t >=  2*`num_periods' & !mi(`event_date')
	assert !mi(t)
end

capture program drop pooled_es_ech
program              pooled_es_ech
syntax, outcome(string) time(string) geo_var(string) num_periods(string) [groups_vars(str) restr(string) sample(str)]

	use  ..\..\..\assign_treatment\output\ech_final_98_2016.dta, clear

	keep if hombre == 0 & inrange(edad, 16, 45) & !mi(impl_date_dpto) & !inlist(dpto,1,3) //drop Montevideo and Canelones

	qui sum impl_date_dpto
	local impl_date_min = `r(min)'
	local impl_date_max = `r(max)'
	if "`time'" == "anio_qtr" {
		keep if inrange(`time', qofd(`impl_date_min') - ${q_pre}, qofd(`impl_date_max') + ${q_post})
		local weight pesotri
		gen post = (`time' >= qofd(impl_date_dpto))
		qui sum `time'
		local min_year = year(dofq(r(min)))
	}
	else if "`time'" == "anio_sem" {
		keep if inrange(`time', hofd(`impl_date_min') - ${s_pre}, hofd(`impl_date_max') + ${s_post})
		local weight pesosem
		gen post = (`time' >= hofd(impl_date_dpto))
		qui sum `time'
		local min_year = year(dofh(r(min)))
	}
	else {
		keep if inrange(`time', yofd(`impl_date_min') - ${y_pre}, yofd(`impl_date_max') + ${y_post})
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
	
	relative_months, num_periods(`num_periods') time(`time') event_date(impl_date_dpto)
	local omitted_month = `num_periods' - 1 //since impl_date marks beginning of post
	tab t,m
	
	* Run regression and plot coefficients
	reg `outcome' ib`omitted_month'.t i.`time' i.`geo_var' `control_vars' ${controls} ///
		[aw = `weight'], vce(cluster `time')
	* Coef plot
	coefplot, vertical baselevels graphregion(color(white)) bgcolor(white) ///
		drop(_cons 0.t 1000.t *.`time' *.`geo_var' `control_vars' ${controls}) ///
		xtitle("Time relative to event (`time')") ytitle(`: var lab `outcome'') ///
		xlabel(1 "-4" 3 "-2" 5 "0" 7 "2" 9 "4" 11 "6")
	graph export ../output/pooled_es_`outcome'_`time'_`geo_var'.pdf, replace
	* Coef plot with shift
	qui sum `outcome' if inrange(t, 0, `num_periods' - 2)
	local target_mean = r(mean)
	preserve
	    coefplot, omitted vertical baselevels gen ///
			drop(_cons 0.t 1000.t *.`time' *.`geo_var' `control_vars' ${controls})
	    qui sum __b
	    local coef_mean = r(mean)
	restore 
	local yshift = `target_mean' - `coef_mean'
	coefplot, vertical baselevels graphregion(color(white)) bgcolor(white) ///
		drop(_cons 0.t 1000.t *.`time' *.`geo_var' `control_vars' ${controls}) ///
	    transform(*= "@ + `yshift'") yline(`target_mean', lpattern(dashed)) ///
		xtitle("Time relative to event (`time')") ytitle(`: var lab `outcome'') ///
		xlabel(1 "-4" 3 "-2" 5 "0" 7 "2" 9 "4" 11 "6")
		
	graph export ../output/pooled_es_shift_`outcome'_`time'_`geo_var'.pdf, replace
end

capture program drop pooled_es_births
program              pooled_es_births
syntax, time(string) geo_var(string) num_periods(string)

	use  ..\..\..\assign_treatment\output\births.dta, clear
	collapse (count) births=edadm (min) impl_date_dpto , by(`time' `geo_var')
	keep if !mi(impl_date_dpto)	
	drop if inlist(dpto,1,3) //drop Montevideo and Canelones

	qui sum impl_date_dpto
	local impl_date_min = `r(min)'
	local impl_date_max = `r(max)'
	if "`time'" == "anio_qtr" {
		keep if inrange(`time', qofd(`impl_date_min') - ${q_pre}, qofd(`impl_date_max') + ${q_post})
		gen post = (`time' >= qofd(impl_date_dpto))
	}
	else if "`time'" == "anio_sem" {
		keep if inrange(`time', hofd(`impl_date_min') - ${s_pre}, hofd(`impl_date_max') + ${s_post})
		gen post = (`time' >= hofd(impl_date_dpto))
	}
	else {
		keep if inrange(`time', yofd(`impl_date_min') - ${y_pre}, yofd(`impl_date_max') + ${y_post})
		gen post = (`time' >= yofd(impl_date_dpto))
	}
	
	relative_months, num_periods(`num_periods') time(`time') event_date(impl_date_dpto)
	local omitted_month = `num_periods' - 1 //since impl_date marks beginning of post
	tab t,m
	
	* Run regression and plot coefficients
	reg births ib`omitted_month'.t i.`time' i.`geo_var', vce(cluster `time')
	* Coef plot
	coefplot, vertical baselevels graphregion(color(white)) bgcolor(white) ///
		drop(_cons 0.t 1000.t *.`time' *.`geo_var') ///
		xtitle("Time relative to event (`time')") ytitle("Number of births") ///
		xlabel(1 "-4" 3 "-2" 5 "0" 7 "2" 9 "4" 11 "6")
	graph export ../output/pooled_es_births_`time'_`geo_var'.pdf, replace
end

main

