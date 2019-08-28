clear all
set more off
adopath + ../../../library/stata/gslab_misc/ado

program main	
	*global y_date_rivera = 2010
	do ../../globals.do
	
	foreach var in not_married first_pregnancy age_young high_school recomm_prenatal_numvisits {
		plot_births_case_studies, treatment(rivera) by_vars(`var') time(anio_sem)
		plot_births_case_studies, treatment(rivera) by_vars(`var') time(anio)
	}

	foreach time in anio anio_sem {
		grc1leg g_`time'_not_marri_0 g_`time'_not_marri_1 g_`time'_first_pre_0 ///
				g_`time'_first_pre_1 g_`time'_age_young_0 g_`time'_age_young_1 ///
			, cols(2) legendfrom(g_`time'_not_marri_0) position(6) ///
			  graphregion(color(white)) name(g_`time')
		graph display g_`time', ysiz(18) xsiz(15)
		graph export "..\output\births_rivera_`time'.pdf", replace
	}
end

capture program drop plot_births_case_studies
program plot_births_case_studies
syntax, by_vars(string) treatment(string) time(string) 
	
	use "..\..\..\assign_treatment\output\births.dta", clear

	if "`time'" == "anio_sem" {
        local range "if inrange(`time', th(${s_date_`treatment'}) - ${s_pre},th(${s_date_`treatment'}) + ${s_post}) "
        local xtitle "Year-half"
        local vertical = th(${s_date_`treatment'}) - 0.5   
        local vertical2= th(${s_date_`treatment'}) + 1.5 
        local y_label = "0(500)1000"
    }
    else {
        local range "if inrange(`time', ${y_date_`treatment'} - ${y_pre}, ${y_date_`treatment'} + ${y_post}) "
        local xtitle "Year"
        local vertical = ${y_date_`treatment'} - 0.5  
        local vertical2= ${y_date_`treatment'} + 0.5
        local y_label = "0(600)1800"
    }
	
	collapse (count) births=edad , by(`time' treatment_`treatment' `by_vars')
	
	keep if !mi(treatment)
	gen Treatment = births if treatment_`treatment'==1
	gen Control   = births if treatment_`treatment'==0
	
	/*tw (scatter Treatment `time' `range', connect(l) mc(blue) lc(blue)) ///
	   (scatter Control   `time' `range', connect(l) mc(red)  lc(red)) ///
	   ,  by(`by_vars', title(${legend_`treatment'}))  ///
	   tline(`vertical' `vertical2', lcolor(black) lpattern(dot)) ///
	   xtitle("`xtitle'") xsize(8) ///
	   scheme(s1color) 

	graph export "..\output\births_`treatment'_`time'_`by_vars'.pdf", replace*/

	local g_name = substr("`by_vars'",1,9)
	local opt1 = `"tline(`vertical' `vertical2', lcolor(black) lpattern(dot)) xsize(4) scheme(s1color) "'
	local opt2 = `"ylabel(`y_label', labs(small)) xlabel(, labs(small)) xtitle("`xtitle'", si(small)) legend(si(vsmall))"'
	forvalues v=0/1 {
		tw (scatter Treatment `time' `range' & `by_vars'==`v', connect(l) mc(blue) lc(blue) ) ///
		   (scatter Control   `time' `range' & `by_vars'==`v', connect(l) mc(red)  lc(red)) ///
			, `opt1' `opt2' title(`: label `by_vars' `v'', si(medium)) name(g_`time'_`g_name'_`v')
	}
end

capture program drop diff_in_diff
program diff_in_diff
syntax, by_vars(string) treatment(string) time(string)
	
	use "..\..\..\assign_treatment\output\births.dta", clear

	local treatment rivera
	local time anio
	local by_vars first_pregnancy

	if "`time'" == "anio_sem" {
        local range "if inrange(`time', th(${s_date_`treatment'}) - ${s_pre},th(${s_date_`treatment'}) + ${s_post}) "
        local event_date         ${s_date_`treatment'}  
        gen post = (`time' >= th(${s_date_`treatment'}))   
    }
    else {
        local range "if inrange(`time', ${y_date_`treatment'} - ${y_pre}, ${y_date_`treatment'} + ${y_post}) "
        local event_date ${y_date_`treatment'}  
        gen post = (`time' >=  ${y_date_`treatment'})  
    }
	
	keep if !mi(treatment_`treatment')
	
	reg edad post##treatment_`treatment'

	collapse (count) births=edad , by(anio treatment_`treatment' first_pregnancy not_married) //`by_vars')
		
		gen post = (anio>`event_date')
		gen interaction = post * treatment_`treatment'
		gen log_births = log(births)
		
		reg log_births post##treatment_`treatment'##first_pregnancy##not_married
end

main
