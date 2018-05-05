clear all
set more off
adopath + ../../../library/stata/gslab_misc/ado

program main	
	*global y_date_rivera = 2010
	do ../../globals.do
	
	foreach var in not_married first_pregnancy age_young high_school recomm_prenatal_numvisits {
		plot_births, treatment(rivera) by_vars(`var') time(anio_mon)
		plot_births, treatment(rivera) by_vars(`var') time(anio_sem)
		plot_births, treatment(rivera) by_vars(`var') time(anio_qtr)
		plot_births, treatment(rivera) by_vars(`var') time(anio)
	}
	grc1leg g_anio_sem_not_marri_0 g_anio_sem_not_marri_1 g_anio_sem_first_pre_0 ///
			g_anio_sem_first_pre_1 g_anio_sem_age_young_0 g_anio_sem_age_young_1 ///
		, cols(2) legendfrom(g_anio_sem_not_marri_0) position(6) ///
		  graphregion(color(white)) name(g_anio_sem)
	graph display g_anio_sem, ysiz(18) xsiz(15)
	graph export "..\output\births_rivera_anio_sem.pdf", replace
end

capture program drop plot_births
program plot_births
syntax, by_vars(string) treatment(string) time(string) 
	
	use "..\..\..\assign_treatment\output\births.dta", clear

	if "`time'" == "anio_mon" {
        local range "if inrange(`time', tm(${m_date_`treatment'}) - ${m_pre},tm(${m_date_`treatment'}) + ${m_post}) "
        local xtitle "Year-month"
        local vertical = tm(${m_date_`treatment'}) - 0.5    
        local vertical2= tm(${m_date_`treatment'}) - 6.5 
    }
	else if "`time'" == "anio_qtr" {
        local range "if inrange(`time', tq(${q_date_`treatment'}) - ${q_pre},tq(${q_date_`treatment'}) + ${q_post}) "
        local xtitle "Year-quarter"
        local vertical = tq(${q_date_`treatment'}) - 0.5 
        local vertical2= tq(${q_date_`treatment'}) + 2.5    
    }
    else if "`time'" == "anio_sem" {
        local range "if inrange(`time', th(${s_date_`treatment'}) - ${s_pre},th(${s_date_`treatment'}) + ${s_post}) "
        local xtitle "Year-half"
        local vertical = th(${s_date_`treatment'}) - 0.5   
        local vertical2= th(${s_date_`treatment'}) + 1.5 
    }
    else {
        local range "if inrange(`time', ${y_date_`treatment'} - ${y_pre}, ${y_date_`treatment'} + ${y_post}) "
        local xtitle "Year"
        local vertical = ${y_date_`treatment'} - 0.5  
        local vertical2= ${y_date_`treatment'} + 0.5
    }
	
	collapse (count) births=edadm , by(`time' treatment_`treatment' `by_vars')
	
	keep if !mi(treatment)
	gen Treatment = births if treatment_`treatment'==1
	gen Control   = births if treatment_`treatment'==0
	
	tw (scatter Treatment `time' `range', connect(l) mc(blue) lc(blue)) ///
	   (scatter Control   `time' `range', connect(l) mc(red)  lc(red)) ///
	   ,  by(`by_vars', title(${legend_`treatment'}))  ///
	   tline(`vertical' `vertical2', lcolor(black) lpattern(dot)) ///
	   xtitle("`xtitle'") xsize(8) ///
	   scheme(s1color) 

	graph export "..\output\births_`treatment'_`time'_`by_vars'.pdf", replace

	local g_name = substr("`by_vars'",1,9)
	local opt1 = `"tline(`vertical' `vertical2', lcolor(black) lpattern(dot)) xsize(6) "'
	local opt2 = `"scheme(s1color) ylabel(0(250)1000) xtitle("`xtitle'") legend(si(small))"'
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

	if "`time'" == "anio_mon" {
        local range "if inrange(`time', tm(${m_date_`treatment'}) - ${m_pre},tm(${m_date_`treatment'}) + ${m_post}) "
        local event_date         ${m_date_`treatment'}   
        gen post = (`time' >= tm(${m_date_`treatment'})) 
    }
	else if "`time'" == "anio_qtr" {
        local range "if inrange(`time', tq(${q_date_`treatment'}) - ${q_pre},tq(${q_date_`treatment'}) + ${q_post}) "
        local event_date         ${q_date_`treatment'}  
        gen post = (`time' >= tq(${q_date_`treatment'}))  
    }
    else if "`time'" == "anio_sem" {
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
	
	reg edadm post##treatment_`treatment'

	collapse (count) births=edadm , by(anio treatment_`treatment' first_pregnancy not_married) //`by_vars')
		
		gen post = (anio>`event_date')
		gen interaction = post * treatment_`treatment'
		gen log_births = log(births)
		
		reg log_births post##treatment_`treatment'##first_pregnancy##not_married
end

main
