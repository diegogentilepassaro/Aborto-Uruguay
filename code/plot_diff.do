clear all
set more off

program main_diff_analysis
	local outcome_vars   "trabajo horas_trabajo"
	local n_outcomes: word count `outcome_vars'
	local stub_list      "Employment Hours-worked"
	
	* In the following lists each ~column~ represents one research design
	local treatment_list "salto rivera"
	local control_list   "paysandu rivera"
	local event_list     "ive rivera"
	*local tline_list_sem     "2013h1 2010h2"	
	local tline_list     "2013q1 2010q3"
	local rd : word count `treatment_list'
	
	local restr "inrange(edad, 14, 45)"
	
	forval j=1/`n_outcomes' {
	    local var: word `j' of `outcome_vars'
	    local stub_var: word `j' of `stub_list'
		
		forvalues i=1/`rd' {
			local t  : word `i' of `treatment_list'
			local c  : word `i' of `control_list'
			local e  : word `i' of `event_list'
			local tl : word `i' of `tline_list'
			
			plot_diff, outcome(`var') stub_var(`stub_var') treatment(`t')  ///
			    control(`c') event(`e') tline(`tl') restr(`restr')
			reg_diff,  outcome(`var') treatment(`t')  ///
			    control(`c') event(`e') tline(`tl') restr(`restr')
		}
	}
end

program plot_diff
    syntax , outcome(string) stub_var(string) treatment(string) control(string) event(string) ///
        tline(string) [restr(string)]
		
   	use  ..\base\ech_final_98_2016.dta, clear

	cap keep if `restr'

	keep if treatment_`treatment'==1 | control_`control'==1
	
	* Collapse such that we get a different row for different study groups in each quarter
	preserve
		collapse (mean) `outcome' [aw = pesotri] if treatment_`treatment' == 1 , by(anio_qtr)
		tsset anio_qtr
		tssmooth ma `outcome' = `outcome', window(1 1 1) replace
		gen treat = 1
		save ../temp/treat_`outcome'_ts.dta, replace
	restore
	
	collapse (mean) `outcome' [aw = pesotri] if control_`control' == 1 , by(anio_qtr)
	tsset anio_qtr
	tssmooth ma `outcome' = `outcome', window(1 1 1) replace
	save ../temp/control_`outcome'_ts.dta, replace
	append using ../temp/treat_`outcome'_ts.dta
	replace treat = 0 if missing(treat)
		
    local range "if inrange(anio_qtr, tq(`tline') - 12,tq(`tline') + 12) "
	
	twoway (line `outcome' anio_qtr if treat == 1) ///
	       (line `outcome' anio_qtr if treat == 0) `range', /// 
		   legend(label(1 "Treatment") label(2 "Control")) ///
		   tline(`tline', lcolor(black) lpattern(dot)) ///
		   graphregion(color(white)) bgcolor(white) xtitle("Year-qtr") ///
		   ytitle("`stub_var'")
    graph export ../figures/`outcome'_`treatment'.png, replace
end

program reg_diff
    syntax, outcome(varname) treatment(string) control(string) event(string) ///
        tline(string) [restr(string)]
		
   	use  ..\base\ech_final_98_2016.dta, clear
    
	cap keep if `restr'

	keep if treatment_`treatment'==1 | control_`control'==1
	
	local range "if inrange(anio_qtr, tq(`tline') - 12,tq(`tline') + 12) "
    
	gen interaction = treatment_`treatment' * post_`event'
	reg `outcome' i.treatment_`treatment' i.post_`event' interaction ///
	    i.anio_qtr cantidad_personas hay_menores edad married ///
		y_hogar `range' [aw = pesotri]
    
	esttab using ../tables/did_`outcome'_`treatment'.tex, label se ///
	    ar2 compress replace nonotes keep(interaction)
	drop interaction
end

main_diff_analysis
