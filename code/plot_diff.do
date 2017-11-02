clear all
set more off

program main_diff_analysis
	local outcome_vars   = "trabajo horas_trabajo"
	local stub_list      = "Employment Hours-worked"
	
	local date_is_chpr "2002q1"
	local date_rivera "2010q3"
	local date_ive "2013q1"

	local restr "inrange(edad, 14, 45)"
	
	/*plot_diff, outcomes(`outcome_vars') stubs(`stub_list'') treatment(mvd)  ///
	    control(mvd) event_date(`date_is_chpr') ///
		weight(pesotri) time(anio_qtr) city_legend(Montevideo) restr(`restr')

	plot_diff, outcomes(`outcome_vars') stubs(`stub_list'') treatment(rivera)  ///
	    control(artigas) event_date(`date_rivera') ///
		weight(pesotri) time(anio_qtr) city_legend(Rivera) restr(`restr')
		
	plot_diff, outcomes(`outcome_vars') stubs(`stub_list'') treatment(salto)  ///
	    control(paysandu) event_date(`date_ive') ///
		weight(pesotri) time(anio_qtr) city_legend(Salto) restr(`restr')*/
		
	reg_diff, outcomes(`outcome_vars') treatment(mvd)  ///
	    control(mvd) event(Female) event_date(`date_is_chpr') ///
		weight(pesotri) time(anio_qtr) restr(`restr')

	reg_diff, outcomes(`outcome_vars') treatment(rivera)  ///
	    control(artigas) event(Rivera) event_date(`date_rivera') ///
		weight(pesotri) time(anio_qtr) restr(`restr')
		
	reg_diff, outcomes(`outcome_vars') treatment(salto)  ///
	    control(paysandu) event(Salto) event_date(`date_ive') ///
		weight(pesotri) time(anio_qtr) restr(`restr')		
end

program plot_diff
    syntax , outcomes(string) stubs(string) treatment(string) control(string) ///
        event_date(string) weight(string) time(string) city_legend(string) [restr(string)]
		
   	use  ..\base\ech_final_98_2016.dta, clear

	cap keep if `restr'

	keep if treatment_`treatment'==1 | control_`control'==1
	
	save ..\temp\did_sample.dta, replace
	
	local n_outcomes: word count `outcomes'
	
	forval i = 1/`n_outcomes' {
		local outcome: word `i' of `outcomes'
		local stub_var: word `i' of `stubs'
		
		use ..\temp\did_sample.dta, clear
		
        preserve
			collapse (mean) `outcome' [aw = `weight'] if treatment_`treatment' == 1 , by(`time')
			tsset `time'
			tssmooth ma `outcome' = `outcome', window(1 1 1) replace
			gen treat = 1
			save ../temp/treat_`outcome'_ts.dta, replace
		restore
		
		collapse (mean) `outcome' [aw = `weight'] if control_`control' == 1 , by(`time')
		tsset `time'
		tssmooth ma `outcome' = `outcome', window(1 1 1) replace
		save ../temp/control_`outcome'_ts.dta, replace
		append using ../temp/treat_`outcome'_ts.dta
		replace treat = 0 if missing(treat)
			
		if "`time'" == "anio_qtr" {
			local range "if inrange(`time', tq(`event_date') - 12,tq(`event_date') + 12) "
			local xtitle "Year-qtr"
		}
		else {
			local range "if inrange(`time', th(`event_date') - 6,th(`event_date') + 6) "
			local xtitle "Year-half"
		}

		qui twoway (line `outcome' `time' if treat == 1) ///
			   (line `outcome' `time' if treat == 0) `range', /// 
			   legend(label(1 "Treatment") label(2 "Control")) ///
			   tline(`event_date', lcolor(black) lpattern(dot)) ///
			   graphregion(color(white)) bgcolor(white) xtitle("`xtitle'") ///
			   ytitle("`stub_var'") name(`outcome'_`treatment', replace) ///
			   title("`stub_var'", color(black) size(medium)) ///

		}
		
	forval i = 1/`n_outcomes' {
		local outcome: word `i' of `outcomes'
		local plots = "`plots' " + "`outcome'_`treatment'"
	}
		
	local plot1: word 1 of `plots' 	
	
	grc1leg `plots', rows(`n_outcomes') legendfrom(`plot1') position(6) /// /* cols(1) or cols(3) */
		   graphregion(color(white)) title({bf: `city_legend' `special_legend'}, color(black) size(small))
	*graph display, ysize(8.5) xsize(6.5)
	graph export ../figures/did_`treatment'.png, replace
		
end

program reg_diff
    syntax, outcomes(string) treatment(string) control(string) ///
        event_date(string) event(string) weight(string) time(string) [restr(string)]
		
   	use  ..\base\ech_final_98_2016.dta, clear
    
	cap keep if `restr'

	keep if treatment_`treatment'==1 | control_`control'==1
	
	if "`time'" == "anio_qtr" {
		local range "if inrange(`time', tq(`event_date') - 12,tq(`event_date') + 12) "
		}
	else {
		local range "if inrange(`time', th(`event_date') - 6,th(`event_date') + 6) "
		}

	local n_outcomes: word count `outcomes'
	forval i = 1/`n_outcomes' {
		local outcome: word `i' of `outcomes'
		
		if "`time'" == "anio_qtr" {
		    gen post = (`time' >= tq(`event_date'))
			} 
			else {
			gen post = (`time' >= th(`event_date')
			}
		gen interaction = treatment_`treatment' * post
		
				
		eststo: reg `outcome' i.treatment_`treatment' i.post interaction ///
					i.`time' cantidad_personas hay_menores edad married ///
					y_hogar `range' [aw = `weight']
		
		drop interaction post
		}
		esttab using ../tables/did_`treatment'.tex, label se ar2 compress ///
		    replace nonotes coeflabels(interaction "`event' x Post") keep(interaction)
		eststo clear
end

main_diff_analysis
