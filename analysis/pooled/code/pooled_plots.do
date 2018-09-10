clear all
set more off

program main
	qui do ../../globals.do
	global controls = "nbr_people ind_under14 edad single poor"
	
	create_births_data,     time(anio_sem) num_periods(6) by_vars(single kids_before)
	local outcomes = "GFR GFR_single0    GFR_single1    GFR_kids_before0    GFR_kids_before1 " + ///
				  " births births_single0 births_single1 births_kids_before0 births_kids_before1 "
	pooled_coefplot,   time(anio_sem) num_periods(6) data(births_wide) outcomes(`outcomes')
	pooled_mean_plots, time(anio_sem) num_periods(6) outcomes(`outcomes')
	pooled_coefplot,   time(anio_sem) num_periods(6) data(births_ind) outcomes(lowbirthweight apgar1_low recomm_prenatal_numvisits preg_preterm)
	
	local labor_vars   = "trabajo horas_trabajo work_part_time"
	pooled_coefplot, data(ech_labor) time(anio_sem) num_periods(6) outcomes(`labor_vars')
	local educ_vars   = "educ_HS_diploma educ_some_college anios_secun anios_terc"
	pooled_coefplot, data(ech_educ) time(anio_sem) num_periods(6) outcomes(`educ_vars')
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
syntax, time(str) by_vars(str)
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

	foreach outcome in `by_vars' {
		use  ..\..\..\assign_treatment\output\ech_final_98_2016.dta, clear
		keep if hombre==0 & age_fertile==1
		collapse (count) pop_`outcome'=pers [pw=pesoan], by(anio dpto `outcome')
		sort anio dpto `outcome'
		egen tot_`outcome' = total(pop), by(anio dpto)
		gen pop_sh_`outcome' = pop/tot
		keep if `outcome'==1
		xtset dpto anio
		tssmooth ma pop_sh_`outcome' = pop_sh_`outcome', w(2 1 2) replace
		isid anio dpto
		keep anio dpto pop_sh_`outcome'
		keep if inrange(anio,1999,2015)
		save ../temp/sh_`outcome'.dta, replace
	}

	use ..\..\..\derived\output\population_fertile_age.dta, clear
	collapse (sum) pop, by(depar anio)
	save ../temp/pop_fertile_age_agg.dta, replace
end

program create_births_data
syntax, time(str) by_vars(str) num_periods(str)
	compute_TFR, time(`time') by_vars(`by_vars')
	use  ..\..\..\assign_treatment\output\births.dta, clear
	keep if (!mi(treatment)|dpto==1) & age_fertile==1 & !mi(impl_date_dpto) 
	save ../temp/plots_sample_births_ind.dta, replace

	foreach by_var in `by_vars' {
		forvalues i=0/1 {
			preserve
				keep if !mi(`by_var') & `by_var'==`i'
				collapse (count) births_`by_var'`i'_l=edad, by(`time' dpto treatment)
				gen births_`by_var'`i' = log(births_`by_var'`i'_l)
				lab var births_`by_var'`i'_l "Number of births"
				lab var births_`by_var'`i' "(log) Number of births"
				tempfile births_`by_var'`i'
				save `births_`by_var'`i''
			restore
		}
		preserve
			keep if !mi(`by_var')
			collapse (count) births_l=edad (min) impl_date_dpto, by(`time' dpto depar treatment `by_var')
			gen births = log(births_l)
			tempfile births_`by_var'
			save `births_`by_var''
		restore
	}

	collapse (count) births_l=edad (min) impl_date_dpto , by(`time' dpto depar treatment)
	gen births = log(births_l)
	merge 1:1 `time' dpto using ..\temp\TFR_`time'.dta, assert(3) nogen
	lab var births_l "Number of births"
	lab var births "(log) Number of births"
	tempfile births_agg
	save `births_agg'

	merge 1:1 `time' dpto using `births_single0'      , assert(3) nogen
	merge 1:1 `time' dpto using `births_single1'      , assert(3) nogen
	merge 1:1 `time' dpto using `births_kids_before0' , assert(3) nogen
	merge 1:1 `time' dpto using `births_kids_before1' , assert(3) nogen
	gen age_fertile = 1
	assert births_l >= births_single0_l + births_single1_l
	gen anio = year(dofh(anio_sem))
	merge m:1 depar anio using ../temp/pop_fertile_age_agg.dta, assert(2 3) keep(3) nogen
	gen GFR = births_l/pop*1000
	lab var GFR "General Fertility Rate"
	foreach by_var in `by_vars' {
		merge m:1 dpto  anio using ../temp/sh_`by_var'.dta, assert(2 3) keep(3) nogen
		gen GFR_`by_var'1 = births_`by_var'1_l/(pop*(  pop_sh_`by_var'))*1000
		gen GFR_`by_var'0 = births_`by_var'0_l/(pop*(1-pop_sh_`by_var'))*1000 
		lab var GFR_`by_var'1 "General fertility rate"
		lab var GFR_`by_var'0 "General fertility rate"
		drop pop_sh_`by_var'
	}
	save ../temp/plots_sample_births_wide.dta, replace
	
	use `births_agg', clear	
	gen all_sample = 1
	append using `births_single'
	append using `births_kids_before'
	gen age_fertile = 1
	assert mi(single) & mi(all_sample) if !mi(kids_before)
	assert dpto==1 if mi(treatment)
	if "`time'" == "anio_sem" {
		gen post = (`time' >= hofd(impl_date_dpto))
	}
	else {
		gen post = (`time' >= yofd(impl_date_dpto))
	}
	gen anio = year(dofh(anio_sem))
	merge m:1 depar anio using ../temp/pop_fertile_age_agg.dta, assert(2 3) keep(3) nogen
	gen GFR = births_l/pop*1000 if all_sample==1
	lab var GFR "General Fertility Rate"
	foreach by_var in `by_vars' {
		merge m:1 dpto  anio using ../temp/sh_`by_var'.dta, assert(2 3) keep(3) nogen
		replace GFR = births_l/(pop*(  pop_sh_`by_var'))*1000 if `by_var'==1 & mi(GFR)
		replace GFR = births_l/(pop*(1-pop_sh_`by_var'))*1000 if `by_var'==0 & mi(GFR)
		drop pop_sh_`by_var'
	}
	save ../temp/plots_sample_births_long.dta, replace
end

capture program drop pooled_coefplot
program              pooled_coefplot
syntax, data(str) time(str) num_periods(int) outcomes(str) [groups_vars(str) restr(str)]

	if substr("`data'",1,3) == "ech" {
		use  ..\..\..\assign_treatment\output\ech_final_98_2016.dta, clear
		local all_controls = "c98_* ${controls}"
		if "`data'" == "ech_labor" {
			keep if hombre == 0 & inrange(horas_trabajo,0,100) //& inrange(edad, 16, 45)
		}
		else {
			keep if hombre == 0 
		} 
	}
	else if "`data'" == "births_ind" {
		use ../temp/plots_sample_births_ind.dta, clear
		local all_controls = ""
	}
	else  {
		use  ..\temp\plots_sample_births_wide.dta, clear
		local all_controls = ""
		tab dpto
	}
	relative_time, num_periods(`num_periods') time(`time') event_date(impl_date_dpto)
	local omitted = `num_periods'+1 //tr_t = treatment*t
	di "Omitted period: -1 (prior to implementation) or t=`omitted'."

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
	if substr("`data'",1,3) == "ech" {
		replace `weight' = int(`weight')
		local pweight = "[pw = `weight']"
	}
	else {
		local pweight = ""
	}
	drop if anio_sem >=hofd(td(01jul2013))
	save ../temp/plots_sample_`data'.dta, replace

	local n_outcomes: word count `outcomes'
    forval i = 1/`n_outcomes' {
        local outcome: word `i' of `outcomes'

        use ../temp/plots_sample_`data'.dta, clear
		
		if substr("`outcome'",1,7) == "births_" {
			local ylabel = "ylabel(-1 (0.5) 0.5)"
		}
		else if substr("`outcome'",1,4) == "GFR_" {
			local ylabel = "ylabel(-20 (10) 20)"
		}
		else {
			local ylabel = ""
		}

		if inlist("`outcome'","horas_trabajo","work_part_time") {
            keep if trabajo==1
        }

		//local ES_subsample  = " if (treatment==1 | dpto==1) & age_fertile==1 "
		//local ES_subsample_nomvd  = " if (treatment==1)     & age_fertile==1 "
		local DiD_subsample = " if !mi(treatment)           & age_fertile==1 "
		local coefplot_opts = " vertical baselevels graphregion(color(white)) bgcolor(white) " + ///
							  " xline(6.5 7.5, lcolor(black) lpattern(dot))	`ylabel' " + ///
							  " ytitle(`: var lab `outcome'') "
		
		* ES: run main regression and plot coefficients
		/*reg `outcome' ib`omitted'.t i.`time' i.dpto  ///
			`ES_subsample_nomvd' `pweight', vce(cluster dpto)
			* Coef plot
		    coefplot, `coefplot_opts' xtitle("`time_label'") ///
				drop(_cons 1.t 1000.t *.`time' *.dpto  `all_controls') ///
				xlabel(1 "-6" 3 "-4" 5 "-2" 7 "0" 9 "2" 11 "4" 13 "6") 
			graph export ../output/pooled_es_`outcome'_`time'_nomvd.pdf, replace

		reg `outcome' ib`omitted'.t i.`time' i.dpto  ///
			`ES_subsample' `pweight', vce(cluster dpto)
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
			graph export ../output/pooled_es_shift_`outcome'_`time'.pdf, replace*/
			
		* DiD: run main regression and plot coefficientss
		reghdfe `outcome' ib`omitted'.t##i.treatment i.`time' i.dpto `all_controls' ///
			`DiD_subsample' `pweight', noabsorb base cluster(`time' dpto)
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

program pooled_mean_plots
syntax, outcomes(str) time(str) num_periods(int)
	use ../temp/plots_sample_births_wide.dta, clear
	if "`time'" == "anio_sem" {
		local time_label "Semesters relative to IS implementation"
	}
	else {
		local time_label "Years relative to IS implementation"
	}
	
	foreach outcome in `outcomes' {
		local opts "graphregion(color(white)) bgcolor(white) xline(7.5 8.5, lcolor(black) lpattern(dot)) ysize(3)"
		
		* Mean DiD
		egen T_`outcome' = mean(`outcome') if treatment==1, by(t)
		egen C_`outcome' = mean(`outcome') if treatment==0, by(t)
		sort t dpto treatment `by_var'
		gen     D_`outcome'   = T_`outcome' - C_`outcome'[_n-2] if treatment==1
		lab var T_`outcome' "`: var lab `outcome''"
		lab var C_`outcome' "`: var lab `outcome''"
		lab var D_`outcome' "`: var lab `outcome''"
		tw (connected T_`outcome' t if inrange(t,2,14), sort mc(blue) lc(blue)) ///
		   (connected C_`outcome' t if inrange(t,2,14), sort mc(red)  lc(red)), ///
			legend(label(1 "Treatment") label( 2 "Control")) ///
			`opts' xtitle("`time_label'") xlabel(2 "-6" 4 "-4" 6 "-2" 8 "0" 10 "2" 12 "4" 14 "6")
		graph export ../output/pooled_did2_avg_`outcome'_`time'.pdf, replace
		tw connected D_`outcome' t if inrange(t,2,14), sort mc(blue) lc(blue) ///
			`opts' xtitle("`time_label'") xlabel(2 "-6" 4 "-4" 6 "-2" 8 "0" 10 "2" 12 "4" 14 "6")
		graph export ../output/pooled_did_avg_`outcome'_`time'.pdf, replace
		
		* Mean ES
		egen         avg_`outcome' = mean(`outcome') if (treatment==1|dpto==1), by(t)
		lab var      avg_`outcome' "`: var lab `outcome''"
		tw connected avg_`outcome' t if inrange(t,2,14), sort mc(blue) lc(blue) ///
			`opts' xtitle("`time_label'") xlabel(2 "-6" 4 "-4" 6 "-2" 8 "0" 10 "2" 12 "4" 14 "6")
		graph export ../output/pooled_es_avg_`outcome'_`time'.pdf, replace
		
		egen         avg_`outcome'_2 = mean(`outcome') if (treatment==1), by(t)
		lab var      avg_`outcome'_2 "`: var lab `outcome''"
		tw connected avg_`outcome'_2 t if inrange(t,2,14), sort mc(blue) lc(blue) ///
			`opts' xtitle("`time_label'") xlabel(2 "-6" 4 "-4" 6 "-2" 8 "0" 10 "2" 12 "4" 14 "6")
		graph export ../output/pooled_es_avg_`outcome'_`time'_nomvd.pdf, replace
	}
end

main

