clear all
set more off

program main_diff_analysis
	local outcome_vars   "trabajo horas_trabajo"
	
	* In the following lists each ~column~ represents one research design
	local treatment_list "salto rivera mvd_city mvd_perif"
	local control_list   "paysandu rivera mvd_city mvd_perif"
	local event_list     "ive rivera is_chpr n369"
	local tline_list     "2012q4 2010q2 2002q1 2004q4"
	local rd : word count `treatment_list'
	
	foreach var in `outcome_vars' {
		forvalues i=1/`rd' {
			local t  : word `i' of `treatment_list'
			local c  : word `i' of `control_list'
			local e  : word `i' of `event_list'
			local tl : word `i' of `tline_list'
			di "outcome  : `var'"
			di "treatment: `t'"
			di "control  : `c'"
			di "event    : `e'"
			plot_diff, outcome(`var') treatment(`t')  control(`c') event(`e') tline(`tl')
			reg_diff,  outcome(`var') treatment(`t')  control(`c') event(`e') tline(`tl')
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
		
    local restr "if inrange(anio_qtr, tq(`tline') - 12,tq(`tline') + 12) "
	
	cap label var trabajo "Employment"
	cap label var horas_trabajo "Hours worked"
	
	twoway (line `outcome' anio_qtr if treat == 1) ///
	       (line `outcome' anio_qtr if treat == 0) `restr', /// 
		   legend(label(1 "Treatment") label(2 "Control")) ///
		   tline(`tline', lcolor(black) lpattern(dot)) ///
		   graphregion(color(white)) bgcolor(white) xtitle("Year-qtr")
    graph export ../figures/`outcome'_`treatment'.png, replace
end

program reg_diff
syntax, outcome(varname) treatment(string) control(string) event(string) tline(string)
   	use  ..\base\ech_final_98_2016.dta, clear
	
	keep if treatment_`treatment'==1 | control_`control'==1
	
	local restr "if inrange(anio_qtr, tq(`tline') - 12,tq(`tline') + 12) "
    
	gen interaction = treatment_`treatment' * post_`event'
	reg `outcome' i.treatment_`treatment' i.post_`event' interaction ///
	    i.anio_qtr i.dpto edad married y_hogar `restr' [aw = pesotri]
    
	esttab using ../tables/did_`outcome'_`treatment'.tex, label se ///
	    ar2 compress replace nonotes keep(interaction)
	drop interaction
end

main_diff_analysis
