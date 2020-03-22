clear all
set more off
adopath + ../../../library/stata/gslab_misc/ado

program main
	qui do ../../globals.do
	
	create_births_data,     time(anio_sem) num_periods(6) by_vars(single kids_before)
	
	use ../temp/plots_sample_births_wide.dta, clear
	relative_time, num_periods(6) time(anio_sem) event_date(IS_impl_date)
	save_data ../temp/plots_sample_births_wide.dta, key(dpto anio_sem) replace
	
	use ../temp/plots_sample_births_ind.dta, clear
	relative_time, num_periods(6) time(anio_sem) event_date(IS_impl_date)
    save_data ../temp/plots_sample_births_ind.dta, key(birth_id) replace

	use ..\..\..\derived\ECH\output\main_ECH_panel.dta, clear
	relative_time, num_periods(6) time(anio_sem) event_date(IS_impl_date)
    save_data ../temp/main_ECH_panel.dta, key(pers numero anio_sem) replace	
end

program create_births_data
syntax, time(str) by_vars(str) num_periods(str)
	compute_TFR, time(`time') by_vars(`by_vars')
	use  ..\..\..\derived\Vitals\output\births_treated_control.dta, clear
	save ../temp/plots_sample_births_ind.dta, replace

	foreach by_var in `by_vars' {
		forvalues i=0/1 {
			preserve
				keep if !mi(`by_var') & `by_var'==`i'
				collapse (count) births_`by_var'`i'_l=edad, by(`time' dpto treated IS_impl_date)
				gen births_`by_var'`i' = log(births_`by_var'`i'_l)
				lab var births_`by_var'`i'_l "Number of births"
				lab var births_`by_var'`i' "(log) Number of births"
				tempfile births_`by_var'`i'
				save `births_`by_var'`i''
			restore
		}
		preserve
			keep if !mi(`by_var')
			collapse (count) births_l=edad, by(`time' dpto treated IS_impl_date `by_var')
			gen births = log(births_l)
			tempfile births_`by_var'
			save `births_`by_var''
		restore
	}

	collapse (count) births_l=edad, by(`time' dpto treated IS_impl_date)
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
	assert births_l >= births_single0_l + births_single1_l
	gen anio = year(dofh(anio_sem))
	merge m:1 dpto anio using ..\..\..\derived\Time_state_panel\output\year_dpto_panel.dta, assert(2 3) keep(3) nogen
	gen GFR = births_l/fertile_women_pop*1000
	lab var GFR "General Fertility Rate"
	foreach by_var in `by_vars' {
		merge m:1 dpto  anio using ../temp/sh_`by_var'.dta, keep(3) nogen
		gen GFR_`by_var'1 = births_`by_var'1_l/(fertile_women_pop*(  pop_sh_`by_var'))*1000
		gen GFR_`by_var'0 = births_`by_var'0_l/(fertile_women_pop*(1-pop_sh_`by_var'))*1000 
		lab var GFR_`by_var'1 "General fertility rate"
		lab var GFR_`by_var'0 "General fertility rate"
		drop pop_sh_`by_var'
	}
	
	save ../temp/plots_sample_births_wide.dta, replace
	
	use `births_agg', clear	
	gen all_sample = 1
	append using `births_single'
	append using `births_kids_before'
	assert mi(single) & mi(all_sample) if !mi(kids_before)
	if "`time'" == "anio_sem" {
		gen post = (`time' >= hofd(IS_impl_date))
	}
	else {
		gen post = (`time' >= yofd(IS_impl_date))
	}
	gen anio = year(dofh(anio_sem))
	merge m:1 dpto anio using ..\..\..\derived\Time_state_panel\output\year_dpto_panel.dta, keep(3) nogen
	gen GFR = births_l/fertile_women_pop*1000 if all_sample==1
	lab var GFR "General Fertility Rate"
	foreach by_var in `by_vars' {
		merge m:1 dpto  anio using ../temp/sh_`by_var'.dta, keep(3) nogen
		replace GFR = births_l/(fertile_women_pop*(  pop_sh_`by_var'))*1000 if `by_var'==1 & mi(GFR)
		replace GFR = births_l/(fertile_women_pop*(1-pop_sh_`by_var'))*1000 if `by_var'==0 & mi(GFR)
		drop pop_sh_`by_var'
	}
	
	gen sample = 1 if all_sample == 1
	replace sample = 2 if single == 1
	replace sample = 3 if single == 0
	replace sample = 4 if kids_before == 1
	replace sample = 5 if kids_before == 0
	save_data ../temp/plots_sample_births_long.dta, key(dpto `time' sample) replace
end

program compute_TFR
syntax, time(str) by_vars(str)
	use ..\..\..\derived\Vitals\output\births_treated_control.dta, clear

	if "`time'" == "anio_sem" {
		local time_label "Semesters"
		local times "anio anio_sem"
	}
	else {
		local time_label "Years"
		local times "anio"
	}

	collapse (count) births=edad, by(`time' age_min age_max dpto IS_impl_date treated)	
	isid `time' age_min age_max dpto
	cap gen anio = year(dofh(`time'))

	merge m:1 dpto age_min age_max anio using ..\..\..\derived\Time_state_age_panel\output\year_dpto_age_panel.dta, keep(3)
	gen TFR_agegroup = births/fertile_women_pop

	collapse (sum) TFR = TFR_agegroup, by(`times' dpto IS_impl_date treated)
	isid `time' dpto
	replace TFR = 5 * TFR
	lab var TFR "Total Fertility Rate"
	keep `time' dpto TFR
	save ../temp/TFR_`time'.dta, replace

	foreach outcome in `by_vars' {
		use  ..\..\..\derived\ECH\output\main_ECH_panel.dta, clear
		collapse (count) pop_`outcome'=pers [pw=pesoan], by(anio dpto `outcome')
		egen tot_`outcome' = total(pop_`outcome'), by(anio dpto)
		gen pop_sh_`outcome' = pop/tot
		keep if `outcome'==1
		isid anio dpto
		keep anio dpto pop_sh_`outcome'
		keep if inrange(anio,2001,2015)
		save ../temp/sh_`outcome'.dta, replace
	}
end

capture program drop relative_time
program              relative_time
syntax, num_periods(int) time(str) event_date(str)
	if "`time'" == "anio_sem" {
		gen t = `time' - hofd(`event_date')
	}
	else {
		gen t = `time' - yofd(`event_date')
	}
	replace t = -1000    if t < -`num_periods'
	replace t = 1000 if t >  `num_periods'
	replace t = t + `num_periods' + 1 if (t != -1000 & t != 1000)
	replace t = 0 if t == -1000
	assert !mi(t)
	tab t, m
end

main
