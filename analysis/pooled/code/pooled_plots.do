clear all
set more off

program main
	qui do ../../globals.do
		
	use ../temp/plots_sample_births_wide.dta, clear
	local outcomes = "GFR GFR_single0 GFR_single1 GFR_kids_before0 GFR_kids_before1 " + ///
				  " births births_single0 births_single1 births_kids_before0 births_kids_before1 "
	local n_outcomes: word count `outcomes'
    forval i = 1/`n_outcomes' {
        local outcome: word `i' of `outcomes'
		pooled_coefplot, time(anio_sem) num_periods(6) ///
	        outcome(`outcome') controls(" ")
		pooled_mean_plots, time(anio_sem) num_periods(6) ///
		    outcome(`outcome')
		}

	use ../temp/plots_sample_births_ind.dta, clear
    local outcomes = "lowbirthweight apgar1_low recomm_prenatal_numvisits preg_preterm"
	local n_outcomes: word count `outcomes'
    forval i = 1/`n_outcomes' {
        local outcome: word `i' of `outcomes'
		pooled_coefplot, time(anio_sem) num_periods(6) ///
	        outcome(`outcome') ///
			controls("c.edadm c.edadm#c.edadm i.first_pregnancy i.married i.high_school i.public_health")
		pooled_mean_plots, time(anio_sem) num_periods(6) ///
		    outcome(`outcome')
		}
	
	use ../temp/main_ECH_panel.dta, clear
	local outcomes   = "trabajo horas_trabajo work_part_time"
	local n_outcomes: word count `outcomes'
    forval i = 1/`n_outcomes' {
        local outcome: word `i' of `outcomes'
		pooled_coefplot, time(anio_sem) num_periods(6) ///
	        outcome(`outcome') ///
			controls("i.blanco i.poor i.car i.married i.public_health c.edad c.nbr_people c.nbr_under14")
		pooled_mean_plots, time(anio_sem) num_periods(6) ///
		    outcome(`outcome')
		}
	/*local educ_vars   = "educ_HS_diploma educ_anios_secun educ_some_college educ_anios_terc"
	pooled_coefplot, data(ech_educ) time(anio_sem) num_periods(6) outcomes(`educ_vars')*/
end

capture program drop pooled_coefplot
program              pooled_coefplot
syntax, time(str) num_periods(int) outcome(str) controls(str) ///
    [pweight(str)]
	
	if "`time'" == "anio_sem" {
		local time_label "Semesters relative to IS implementation"
	}
	else {
		local time_label "Years relative to IS implementation"
	}
	
	local omitted = `num_periods' 
	di "Omitted period: -1 (prior to implementation) or t=`omitted'."

	reghdfe `outcome' ib`omitted'.t##i.treated i.dpto `controls' ///
	    `pweight', absorb(`time') base cluster(dpto)
			

	local coefplot_opts = " vertical baselevels graphregion(color(white)) bgcolor(white) " + ///
						  " xline(6.5 7.5, lcolor(black) lpattern(dot))	`ylabel' " + ///
						  " ytitle(`: var lab `outcome'') "

    local window_span = 2*`num_periods' + 1
	forval i = 1(1)`window_span' {
	    local keep_coeffs = "`keep_coeffs'" + " `i'.t#1.treated"
	}					  
	coefplot, `coefplot_opts' xtitle("`time_label'") ///
		keep(`keep_coeffs') ///
		xlabel(1 "-6" 3 "-4" 5 "-2" 7 "0" 9 "2" 11 "4" 13 "6") 
	graph export ../output/pooled_did_`outcome'_`time'.png, replace
		
	* Coef plot with shift
	qui sum `outcome' if inrange(t, 1, `num_periods')
	local target_mean = r(mean)
	preserve
		coefplot, omitted vertical baselevels gen ///
		keep(`keep_coeffs')
		qui sum __b
		local coef_mean = r(mean)
	restore 
	local yshift = `target_mean' - `coef_mean'
	coefplot, `coefplot_opts' xtitle("`time_label'") ///
		keep(`keep_coeffs') ///
		transform(*= "@ + `yshift'") yline(`target_mean', lpattern(dashed)) ///
		xlabel(1 "-6" 3 "-4" 5 "-2" 7 "0" 9 "2" 11 "4" 13 "6") 		
	graph export ../output/pooled_did_shift_`outcome'_`time'.png, replace
end

program pooled_mean_plots
syntax, time(str) num_periods(int) outcome(str)
	if "`time'" == "anio_sem" {
		local time_label "Semesters relative to IS implementation"
	}
	else {
		local time_label "Years relative to IS implementation"
	}
	
	local opts = "graphregion(color(white)) bgcolor(white) " + ///
	           "xline(7.5 8.5, lcolor(black) lpattern(dot)) ysize(3)"
	
	* Mean DiD
	egen T_`outcome' = mean(`outcome') if treated==1, by(t)
	egen C_`outcome' = mean(`outcome') if treated==0, by(t)
	sort t dpto treated `by_var'
	gen     D_`outcome'   = T_`outcome' - C_`outcome'[_n-2] if treated==1
	lab var T_`outcome' "`: var lab `outcome''"
	lab var C_`outcome' "`: var lab `outcome''"
	lab var D_`outcome' "`: var lab `outcome''"
	tw (connected T_`outcome' t if inrange(t,2,14), sort mc(navy) lc(navy)) ///
	   (connected C_`outcome' t if inrange(t,2,14), sort mc(maroon)  lc(maroon)), ///
		legend(label(1 "Treatment") label( 2 "Control")) ///
		`opts' xtitle("`time_label'") xlabel(2 "-6" 4 "-4" 6 "-2" 8 "0" 10 "2" 12 "4" 14 "6")
	graph export ../output/pooled_did2_avg_`outcome'_`time'.png, replace
	tw connected D_`outcome' t if inrange(t,2,14), sort mc(navy) lc(navy) ///
		`opts' xtitle("`time_label'") xlabel(2 "-6" 4 "-4" 6 "-2" 8 "0" 10 "2" 12 "4" 14 "6")
	graph export ../output/pooled_did_avg_`outcome'_`time'.png, replace
	
	* Mean ES
	egen         avg_`outcome' = mean(`outcome') if (treated==1), by(t)
	lab var      avg_`outcome' "`: var lab `outcome''"
	tw connected avg_`outcome' t if inrange(t,2,14), sort mc(navy) lc(navy) ///
		`opts' xtitle("`time_label'") xlabel(2 "-6" 4 "-4" 6 "-2" 8 "0" 10 "2" 12 "4" 14 "6")
	graph export ../output/pooled_es_avg_`outcome'_`time'.png, replace
end

main

