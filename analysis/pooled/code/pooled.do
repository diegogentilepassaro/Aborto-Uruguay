clear all
set more off

program main
	qui do ../../globals.do
	global controls = "nbr_people ind_under14 edad married y_hogar_alt"

	pooled_es, data(births) time(anio_sem) geo_var(dpto)     num_periods(6) int_mvd(int_mvd)
	pooled_es, data(ech)    time(anio_sem) geo_var(loc_code) num_periods(6) int_mvd(int_mvd) outcome(trabajo)
	pooled_es, data(ech)    time(anio_sem) geo_var(loc_code) num_periods(6) int_mvd(int_mvd) outcome(horas_trabajo)
	pooled_es, data(births) time(anio_sem) geo_var(dpto)     num_periods(6) int_mvd(riv_flo)
	pooled_es, data(ech)    time(anio_sem) geo_var(loc_code) num_periods(6) int_mvd(riv_flo) outcome(trabajo)
	pooled_es, data(ech)    time(anio_sem) geo_var(loc_code) num_periods(6) int_mvd(riv_flo) outcome(horas_trabajo)
end

capture program drop assign_impl_date_mvd
program              assign_impl_date_mvd
	qui sum impl_date_dpto if dpto==1
	replace impl_date_dpto = `r(mean)' if inlist(dpto,3,16)
	qui sum impl_date_dpto             if inlist(dpto,1,3,16)
	assert `r(sd)'==0
end

capture program drop relative_time
program              relative_time
syntax, num_periods(int) time(str) event_date(str)
	if "`time'" == "anio_qtr" { //+1 since impl_date marks beginning of post
		gen t = `time' - qofd(`event_date') + 1 if !mi(`event_date')
	}
	else if "`time'" == "anio_sem" {
		gen t = `time' - hofd(`event_date') + 1 if !mi(`event_date')
	}
	else {
		gen t = `time' - yofd(`event_date') + 1 if !mi(`event_date')
	}
	replace t = t + `num_periods'               if !mi(`event_date') //to make t>=0 for the event window
	replace t = 0    if t < 0                    |  mi(`event_date')
	replace t = 1000 if t >=  2*`num_periods'    & !mi(`event_date')
	assert !mi(t)
end

capture program drop pooled_es
program              pooled_es
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

	if "`int_mvd'" == "int_mvd" {
		assign_impl_date_mvd
		keep if !mi(impl_date_dpto) & !inlist(dpto,1) //drop Montevideo
	}
	else {
		keep if !mi(impl_date_dpto) & !inlist(dpto,1,3,16) //drop Montevideo, San Jose, and Canelones
	}

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
	
	relative_time, num_periods(`num_periods') time(`time') event_date(impl_date_dpto)
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
	* Run regression and plot coefficients
	`estimation' `outcome' ib`num_periods'.t i.`time' i.`geo_var'  `all_controls' `pweight', vce(cluster `time')
	* Coef plot
	coefplot, vertical baselevels graphregion(color(white)) bgcolor(white) ///
		drop(_cons 0.t 1000.t *.`time' *.`geo_var'  `all_controls') ///
		xtitle("Time relative to event (`time')") ytitle(`: var lab `outcome'') ///
		xlabel(2 "-4" 4 "-2" 6 "0" 8 "2" 10 "4")
	graph export ../output/pooled_es_`outcome'_`time'_`geo_var'_`int_mvd'.pdf, replace
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
		xtitle("Time relative to event (`time')") ytitle(`: var lab `outcome'') ///
		xlabel(2 "-4" 4 "-2" 6 "0" 8 "2" 10 "4")
		
	graph export ../output/pooled_es_shift_`outcome'_`time'_`geo_var'_`int_mvd'.pdf, replace
end

main

