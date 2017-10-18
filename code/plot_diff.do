clear all
set more off

program main_diff_analysis
	local outcome_vars   "trabajo"
	* In the following lists each ~column~ represents one research design
	local treatment_list "salto rivera"
	local control_list   "paysandu artigas"
	local event_list     "ive rivera"
	local tline_list     "2012q4 2010q2"
	local rd : word count `treatment_list'
	
	foreach var in `outcome_vars' {
		forvalues i=1/`rd' {
			local t : word `i' of `treatment_list'
			local c : word `i' of `control_list'
			local e : word `i' of `event_list'
			local tl : word `i' of `tline_list'
			di "outcome  : `var'"
			di "treatment: `t'"
			di "control  : `c'"
			di "event    : `e'"
			plot_diff, outcome(`var') treatment(`t')  control(`c') event(`e') tline(`tl')
			reg_diff,  outcome(`var') treatment(`t')  control(`c') event(`e')
		}
	}
end

program plot_diff
syntax , outcome(string) treatment(string) control(string) event(string) tline(string) [restr(string) ]
   	use  ..\base\ech_final_98_2016.dta, clear

	keep if treatment_`treatment'==1 | control_`control'==1
	
	* Collapse such that we get a different row for different study groups in each quarter
	preserve
		collapse (mean) `outcome' [aw = pesotri] if treatment_`treatment' == 1 , by(anio_qtr)
		tsset anio_qtr
		tssmooth ma `outcome'_smooth = `outcome', window(1 1 1)
		gen treat = 1
		save ../temp/treat_`outcome'_ts.dta, replace
	restore
	
	collapse (mean) `outcome' [aw = pesotri] if control_`control' == 1 , by(anio_qtr)
	tsset anio_qtr
	tssmooth ma `outcome'_smooth = `outcome', window(1 1 1)
	save ../temp/control_`outcome'_ts.dta, replace
	append using ../temp/treat_`outcome'_ts.dta
	replace treat = 0 if missing(treat)
		
    local restr "if inrange(anio_qtr, tq(`tline') - 12,tq(`tline') + 12) "
	twoway (line `outcome'_smooth anio_qtr if treat == 1) ///
	       (line `outcome'_smooth anio_qtr if treat == 0) `restr', /// 
		   legend(label(1 "`treatment'") label(2 "`control'")) ///
		   tline(`tline', lcolor(black) lpattern(dot))
		   
end

program reg_diff
syntax, outcome(varname) treatment(string) control(string) event(string)
   	use  ..\base\ech_final_98_2016.dta, clear
	
	keep if treatment_`treatment'==1 | control_`control'==1
	
	reg `outcome' i.treatment_`treatment'##i.post_`event' i.anio_qtr i.dpto [aw = pesotri]	
end

main_diff_analysis
