clear all
set more off

program main_triple_diff
	local labor_vars   = "trabajo horas_trabajo"
	local educ_vars    = "educ_HS_or_more educ_more_HS"  
	local labor_stubs  = `" "Employment" "Hours-worked" "'
	local educ_stubs   = `" "High-school" "Some-college" "'
	
	local q_date_mvd "2002q1"
	local s_date_mvd "2002h1"
	local y_date_mvd "2002"
	
    foreach group_vars in labor /*educ*/ {
	
		foreach design in gender_married /*income_gender income_married*/ {
				
			plot_triple_diff, outcomes(``group_vars'_vars') design(`design') ///
				time(anio_sem) event_date(`s_date_mvd') city(mvd) city_legend(Montevideo) ///
				stubs(``group_vars'_stubs') groups_vars(`group_vars') plot_option(trend)
				
			/*plot_triple_diff, outcomes(``group_vars'_vars') design(`design') ///
				time(anio) event_date(`y_date_mvd') city(mvd) city_legend(Montevideo) ///
				stubs(``group_vars'_stubs') groups_vars(`group_vars') plot_option(trend)*/
				
			reg_triple_diff, outcomes(``group_vars'_vars') design(`design') city(mvd) ///
				time(anio_sem) event_date(`s_date_mvd') groups_vars(`group_vars') 		
				
			/*reg_triple_diff, outcomes(``group_vars'_vars') design(`design') city(mvd) ///
				time(anio) event_date(`y_date_mvd') groups_vars(`group_vars')*/
		}			
	}
end

program plot_triple_diff
	syntax, outcomes(str) design(str) event_date(str) ///
	    stubs(str) time(str) city(str) city_legend(str) ///
		groups_vars(str) [plot_option(str) special_legend(str) sample_restr(str)]
	
	if "`design'" == "income_gender" {
			local group_labels = `""Poor male"   "Poor female"   "Non-poor male"   "Non-poor female""'
			local groups      "mvd_poor_male mvd_poor_female mvd_non_poor_male mvd_non_poor_female"
			local diff1 "Poor: male vs female"
			local diff2 "Non-poor: male vs female"
		}
		else if "`design'" == "income_married" {
			local group_labels = `""Poor single"   "Poor married"   "Non-poor single"   "Non-poor married" "'
			local groups       "mvd_poor_single mvd_poor_married mvd_non_poor_single mvd_non_poor_married"
			local diff1 "Poor: single vs married"
			local diff2 "Non-poor: single vs married"
		}
		else if "`design'" == "gender_married" {
			local group_labels = `""Female single"   "Female married"   "Male single"   "Male married" "'
			local groups       "mvd_female_single mvd_female_married mvd_male_single mvd_female_married"
			local diff1 "Poor: single vs married"
			local diff2 "Non-poor: single vs married"
		}		
		else {
			di as err "The argument of design() must be one of the following: "
			di as err "income_gender"
			di as err "income_married"
			exit
		}
	
	if "`time'" == "anio_qtr" {
			local weight pesotri
			local range "if inrange(`time', tq(`event_date') - 16, tq(`event_date') + 8) "
			local xtitle "Year-qtr"
		}
		else if "`time'" == "anio_sem" {
			local weight pesosem
			local range "if inrange(`time', th(`event_date') - 8, th(`event_date') + 4) "
			local xtitle "Year-half"
		}
		else {
			local weight pesoan
			local range "if inrange(`time', `event_date' - 4, `event_date' + 2) "
			local xtitle "Year"
		}
	
    forval x = 1/4 {
		local group`x'      : word `x' of `groups'
		local group_label`x': word `x' of `group_labels'
	}
	local n_outcomes: word count `outcomes'
	local n_groups  : word count `groups'
	
	forval i = 1/`n_outcomes' {
	    local outcome : word `i' of `outcomes'
	    local stub_var: word `i' of `stubs'
		local plots = " `plots' " + "triple_diff_`outcome'"
		
		use  ..\base\ech_final_98_2016.dta, clear 
		
		keep if inrange(edad, 16, 45)
	    keep if `group1' == 1 | `group2' == 1 | `group3' == 1 | `group4' == 1
			
	    if "`plot_option'" == "diff" {
			forval j = 1/`n_groups' {
				local group: word `j' of `groups'
				preserve
					collapse (mean) `outcome' (sd) sd_`outcome' = `outcome' (count) n_`outcome' = `outcome' ///
						[aw = `weight'] if `group' == 1 , by(`time')
					tsset `time'
					*tssmooth ma `outcome' = `outcome', window(1 1 1) replace
					rename *`outcome' *`outcome'_`j'
					save ../temp/group`j'_`outcome'_ts.dta, replace
				restore
			}
			use                    ../temp/group1_`outcome'_ts.dta, clear
			merge 1:1 `time' using ../temp/group2_`outcome'_ts.dta, assert(3) keep(3) nogen
			merge 1:1 `time' using ../temp/group3_`outcome'_ts.dta, assert(3) keep(3) nogen
			merge 1:1 `time' using ../temp/group4_`outcome'_ts.dta, assert(3) keep(3) nogen
			
			gen `outcome'_diff1 = `outcome'_1 - `outcome'_2
			gen `outcome'_diff1_se = sqrt((sd_`outcome'_1^2/n_`outcome'_1)+(sd_`outcome'_2^2/n_`outcome'_2))
			gen `outcome'_diff2 = `outcome'_3 - `outcome'_4
			gen `outcome'_diff2_se = sqrt((sd_`outcome'_3^2/n_`outcome'_3)+(sd_`outcome'_4^2/n_`outcome'_4))
			
			gen `outcome'_diff1_ci_p = `outcome'_diff1 + 1.96 * `outcome'_diff1_se
		    gen `outcome'_diff1_ci_n = `outcome'_diff1 - 1.96 * `outcome'_diff1_se		
			gen `outcome'_diff2_ci_p = `outcome'_diff2 + 1.96 * `outcome'_diff2_se
		    gen `outcome'_diff2_ci_n = `outcome'_diff2 - 1.96 * `outcome'_diff2_se	

			qui twoway (rarea `outcome'_diff1_ci_p  `outcome'_diff1_ci_n `time' `range', fc(green) lc(bg)    fin(inten20)) ///   
					   (rarea `outcome'_diff2_ci_p  `outcome'_diff2_ci_n `time' `range', fc(blue)  lc(bg)    fin(inten10)) ///   
					   (line  `outcome'_diff1 `time' `range', lc(green) lp(solid) lw(medthick)) /// 
					   (line  `outcome'_diff2 `time' `range', lc(blue)  lp(solid) lw(medthick)) /// 			   
				,legend(on order(3 4) label(3 "`diff1'") label(4 "`diff2'") col(1) row(2)) ///
				tline(`event_date', lcolor(black) lpattern(dot)) ///
				graphregion(color(white)) bgcolor(white) xtitle("`xtitle'") ///
				ytitle("`stub_var'") name(triple_diff_`outcome', replace) ///
				title("`stub_var'", color(black) size(medium)) ylabel(#2)
			
		}
		else {
			forval j = 1/`n_groups' {
				local group: word `j' of `groups'
				preserve
					collapse (mean) `outcome' [aw = `weight'] if `group' == 1 , by(`time')
					tsset `time'
					*tssmooth ma `outcome' = `outcome', window(1 1 0) replace
					gen group = `j'
					save ../temp/group`j'_`outcome'_ts.dta, replace
				restore
			}
			use          ../temp/group1_`outcome'_ts.dta, clear
			append using ../temp/group2_`outcome'_ts.dta
			append using ../temp/group3_`outcome'_ts.dta
			append using ../temp/group4_`outcome'_ts.dta		
				
			qui twoway (scatter `outcome' `time' if group == 1, mc(blue) ms(triangle)) ///
					   (scatter `outcome' `time' if group == 2, mc(red)  ms(triangle)) ///
					   (scatter `outcome' `time' if group == 3, mc(blue)) ///
					   (scatter `outcome' `time' if group == 4, mc(red)) ///
                       (line `outcome' `time' if group == 1, lc(blue)) ///
					   (line `outcome' `time' if group == 2, lc(red)) ///
					   (line `outcome' `time' if group == 3, lc(blue)) ///
					   (line `outcome' `time' if group == 4, lc(red)) `range', /// 
				   legend(on order (1 2 3 4) col(2) label(1 "`group_label1'") label(2 "`group_label2'") ///
				   label(3 "`group_label3'") label(4 "`group_label4'")) ///
				   tline(`event_date', lcolor(black) lpattern(dot)) ///
				   graphregion(color(white)) bgcolor(white) xtitle("`xtitle'") ///
				   ytitle("`stub_var'") name(triple_diff_`outcome', replace) ///
				   title("`stub_var'", color(black) size(medium)) ylabel(#2)
		}

	}

	local plot1: word 1 of `plots' 	
	
	grc1leg `plots', rows(`n_outcomes') legendfrom(`plot1') position(6) /// /* cols(1) or cols(3) */
		   graphregion(color(white)) title({bf: `city_legend' `special_legend'}, color(black) size(small))
	graph display, ysize(8.5) xsize(6.5)
	graph export ../figures/triple_diff_`city'_`time'_`groups_vars'_`design'`plot_option'.png, replace
end

program reg_triple_diff
    syntax, outcomes(string) design(string) city(str) groups_vars(str) time(str) event_date(str)
	
	use  ..\base\ech_final_98_2016.dta, clear
	
	if "`time'" == "anio_qtr" {
			local weight pesotri
			gen post = (`time' >= tq(`event_date'))
			local range "if inrange(`time', tq(`event_date') - 12,tq(`event_date') + 12) "
			qui sum `time' `range'	
			local min_year = year(dofq(r(min)))
		}
		else if "`time'" == "anio_sem" {
			local weight pesosem
			gen post = (`time' >= th(`event_date'))
			local range "if inrange(`time', th(`event_date') - 6,th(`event_date') + 6) "
			qui sum `time' `range'	
			local min_year = year(dofh(r(min)))
		}
		else {
			local weight pesoan
			gen post = (`time' >= `event_date')
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
	
	if "`design'" == "income_gender" {
			local groups      "mvd_poor_female mvd_poor_male mvd_non_poor_female mvd_non_poor_male"
			local event "Poor x Female"
			local gr_vars = "pobre female"
			gen int_no_post = pobre * female
			gen int_post1 = pobre* post
			gen int_post2 = female * post
		}
		else if "`design'" == "income_married" {
			local groups       "mvd_poor_single mvd_poor_married mvd_non_poor_single mvd_non_poor_married"
			local event "Poor x Single"
			local gr_vars = "pobre single"
			gen int_no_post = pobre * single
			gen int_post1 = pobre* post
			gen int_post2 = single * post
		}
		else if "`design'" == "gender_married" {
			local groups       "mvd_female_single mvd_female_married mvd_male_single mvd_female_married"
			local event "Female x Single"			
			local diff1 "Female: single vs married"
			local diff2 "Male: single vs married"
		}		
		else {
			di as err "The argument of design() must be one of the following: "
			di as err "income_gender"
			di as err "income_fertility"
			di as err "gender_fertility"
			exit
		}
		
	forval x = 1/4 {
		local group`x'      : word `x' of `groups'
		local group_label`x': word `x' of `group_labels'
	}
	keep if `group1' == 1 | `group2' == 1 | `group3' == 1 | `group4' == 1
    
	gen int_triple = int_no_post * post

	local n_outcomes: word count `outcomes'
	forval i = 1/`n_outcomes' {
		local outcome: word `i' of `outcomes'
		
		eststo: reg `outcome' `gr_vars' i.post int_* ///
					i.`time' cantidad_personas hay_menores edad married ///
					y_hogar_alt `control_vars' `range' [aw = `weight']
		}
		esttab using ../tables/triple_diff_`city'_`time'_`groups_vars'_`design'.tex, label se ar2 compress ///
			replace nonotes coeflabels(int_triple "`event' x Post") keep(int_triple)
		eststo clear
end

main_triple_diff
