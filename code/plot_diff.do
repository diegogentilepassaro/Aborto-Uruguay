clear all
set more off

program main_diff_analysis
	local labor_vars   = "trabajo horas_trabajo"
	local educ_vars    = "educ_HS_or_more educ_more_HS"
	local outcome_vars = "`labor_vars' " + "`educ_vars'"
	local labor_stubs  = `" "Employment" "Hours-worked" "'
	local educ_stubs   = `" "High-school" "Some-college" "'
	local labor_restr "inrange(edad, 14, 40)"
	local educ_restr "inrange(edad, 18, 25)"
	
	local legend_rivera = "Rivera"
	local legend_salto  = "Salto"
	
	local control_rivera = "artigas"
	local control_salto  = "paysandu"
	
	local q_date_mvd  "2002q1"
	local q_date_rivera  "2010q3"
	local q_date_salto "2013q1"
	
	local s_date_mvd "2002h1"
	local s_date_rivera "2010h2"
	local s_date_salto "2013h1"
	
	local y_date_mvd 2002 
	local y_date_rivera 2010 
	local y_date_salto 2013 

	foreach city in rivera salto {
		
		foreach group_vars in labor educ {

			plot_diff, outcomes(``group_vars'_vars') treatment(`city') control(`control_`city'') ///
				time(anio_qtr) event_date(`q_date_`city'') city_legend(`legend_`city'') ///
				stubs(``group_vars'_stubs') restr(``group_vars'_restr') groups_vars(`group_vars')

			plot_diff, outcomes(``group_vars'_vars') treatment(`city') control(`control_`city'') ///
				time(anio_sem) event_date(`s_date_`city'') city_legend(`legend_`city'') ///
				stubs(``group_vars'_stubs') restr(``group_vars'_restr') groups_vars(`group_vars')

			plot_diff, outcomes(``group_vars'_vars') treatment(`city') control(`control_`city'') ///
				time(anio) event_date(`y_date_`city'') city_legend(`legend_`city'') ///
				stubs(``group_vars'_stubs') restr(``group_vars'_restr') groups_vars(`group_vars')

			reg_diff, outcomes(``group_vars'_vars') treatment(`city') control(`control_`city'')  ///
				time(anio_qtr) event(`legend_`city'') event_date(`q_date_rivera') restr(`restr') ///
				groups_vars(`group_vars')

			reg_diff, outcomes(``group_vars'_vars') treatment(`city') control(`control_`city'')  ///
				time(anio_sem) event(`legend_`city'') event_date(`s_date_rivera') restr(`restr') ///
				groups_vars(`group_vars')

			reg_diff, outcomes(``group_vars'_vars') treatment(`city') control(`control_`city'')  ///
				time(anio)     event(`legend_`city'') event_date(`y_date_rivera') restr(`restr') ///
				groups_vars(`group_vars')
		}
	}
end

program plot_diff
    syntax , outcomes(string) stubs(string) treatment(string) control(string) ///
        event_date(string) time(string) city_legend(string) [groups_vars(str) restr(string) sample(str)]

	if "`time'" == "anio_qtr" {
		local weight pesotri
		local range "if inrange(`time', tq(`event_date') - 28,tq(`event_date') + 8) "
		local xtitle "Year-qtr"
	}
	else if "`time'" == "anio_sem" {
		local weight pesosem
		local range "if inrange(`time', th(`event_date') - 14,th(`event_date') + 4) "
		local xtitle "Year-half"
	}
	else {
		local weight pesoan
		local range "if inrange(`time', `event_date' - 7, `event_date' + 2) "
		local xtitle "Year"
	}
	
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
			collapse (mean) `outcome' (sem) se_`outcome'=`outcome' [aw = `weight'] if treatment_`treatment' == 1 , by(`time')
			tsset `time'
			*tssmooth ma `outcome' = `outcome', window(1 1 1) replace
			gen treat = 1
			save ../temp/treat_`outcome'_ts.dta, replace
		restore
		
		collapse (mean) `outcome' (sem) se_`outcome'=`outcome' [aw = `weight'] if control_`control' == 1 , by(`time')
		tsset `time'
		*tssmooth ma `outcome' = `outcome', window(1 1 1) replace
		save ../temp/control_`outcome'_ts.dta, replace
		append using ../temp/treat_`outcome'_ts.dta
		replace treat = 0 if missing(treat)

		gen `outcome'_ci_p = `outcome' + 1.96*se_`outcome'
		gen `outcome'_ci_n = `outcome' - 1.96*se_`outcome'

		qui twoway (rarea `outcome'_ci_p  `outcome'_ci_n `time' `range' & treat == 1, fc(red)  lc(bg)    fin(inten20)) ///
				   (rarea `outcome'_ci_p  `outcome'_ci_n `time' `range' & treat == 0, fc(blue) lc(bg)    fin(inten10)) ///
				   (line  `outcome'                      `time' `range' & treat == 1, lc(red)  lp(solid) lw(medthick)) ///
				   (line  `outcome'                      `time' `range' & treat == 0, lc(blue) lp(solid) lw(medthick)), ///
			legend(on order(3 4) label(3 "Treatment") label(4 "Control")) ///
			tline(`event_date', lcolor(black) lpattern(dot)) ///
			graphregion(color(white)) bgcolor(white) xtitle("`xtitle'") ///
			ytitle("`stub_var'") name(`outcome'_`treatment', replace) ///
			title("`stub_var'", color(black) size(medium)) ylabel(#2)
		
		/*qui twoway (line `outcome' `time' if treat == 1) ///
			   (line `outcome' `time' if treat == 0) `range', /// 
			   legend(label(1 "Treatment") label(2 "Control")) ///
			   tline(`event_date', lcolor(black) lpattern(dot)) ///
			   graphregion(color(white)) bgcolor(white) xtitle("`xtitle'") ///
			   ytitle("`stub_var'") name(`outcome'_`treatment', replace) ///
			   title("`stub_var'", color(black) size(medium)) ylabel(#2)*/
		}
		
	forval i = 1/`n_outcomes' {
		local outcome: word `i' of `outcomes'
		local plots = "`plots' " + "`outcome'_`treatment'"
	}
		
	local plot1: word 1 of `plots' 	
	
	grc1leg `plots', rows(`n_outcomes') legendfrom(`plot1') position(6) /// /* cols(1) or cols(3) */
		   graphregion(color(white)) title({bf: `city_legend' `special_legend'}, color(black) size(small))
	graph display, ysize(8.5) xsize(6.5)
	graph export ../figures/did_`treatment'_`groups_vars'_`time'.png, replace
		
end

program reg_diff
    syntax, outcomes(string) treatment(string) control(string) ///
        event_date(string) event(string) time(string) [groups_vars(str) restr(string) sample(str)]
		
   	use  ..\base\ech_final_98_2016.dta, clear
    
	cap keep if `restr'

	keep if treatment_`treatment'==1 | control_`control'==1
	
	if "`time'" == "anio_qtr" {
			local weight pesotri
			local range "if inrange(`time', tq(`event_date') - 12,tq(`event_date') + 12) "
			qui sum `time' `range'	
			local min_year = year(dofq(r(min)))
		}
		else if "`time'" == "anio_sem" {
			local weight pesosem
			local range "if inrange(`time', th(`event_date') - 6,th(`event_date') + 6) "
			qui sum `time' `range'	
			local min_year = year(dofh(r(min)))
		}
		else {
			local weight pesoan
			local range "if inrange(`time', `event_date' - 3, `event_date' + 3) "
			qui sum `time' `range'	
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
	
	local n_outcomes: word count `outcomes'
	forval i = 1/`n_outcomes' {
		local outcome: word `i' of `outcomes'
		
		if "`time'" == "anio_qtr" {
				gen post = (`time' >= tq(`event_date'))
			} 
			else if "`time'" == "anio_sem" {
				gen post = (`time' >= th(`event_date'))
			}
			else {
				gen post = (`time' >= `event_date')
			}
			
		gen interaction = treatment_`treatment' * post
		
		sum `control_vars'		
		eststo: reg `outcome' i.treatment_`treatment' i.post interaction ///
					i.`time' cantidad_personas hay_menores edad married ///
					y_hogar_alt `control_vars' `range' [aw = `weight']
		
		drop interaction post
		}
		esttab using ../tables/did_`treatment'_`groups_vars'_`time'.tex, label se ar2 compress ///
		    replace nonotes coeflabels(interaction "`event' x Post") keep(interaction)
		eststo clear
end

main_diff_analysis
