clear all
set more off

program main_triple_diff
	local labor_outcome_vars = "trabajo horas_trabajo"
	local labor_stubs  = `" "Employment" "Hours-worked" "'
	
	local educ_outcome_vars = "educ_HS_or_more educ_more_HS"  
	local educ_stubs   = `" "High-school" "Some-college" "'
	
	local date_is_chpr "2002q1"
	
	local sem_date_is_chpr "2002h1"
	
	local groups "mvd_poor_male mvd_poor_female mvd_non_poor_male mvd_non_poor_female"

    foreach outcome_type in labor educ {
		plot_triple_diff, outcomes(``outcome_type'_outcome_vars') groups(`groups') design(income_gender) ///
			stubs(``outcome_type'_stubs') event_date(`date_is_chpr') time(anio_qtr) ///
			weight(pesotri) city(mvd) city_legend(Montevideo) outcome_type_leg(`outcome_type')
			
		plot_triple_diff, outcomes(``outcome_type'_outcome_vars') groups(`groups') design(income_gender) ///
			stubs(``outcome_type'_stubs') event_date(`sem_date_is_chpr') time(anio_sem) ///
			weight(pesosem) city(mvd) city_legend(Montevideo) outcome_type_leg(`outcome_type')
			
		local groups "mvd_poor_fertile mvd_poor_infertile mvd_non_poor_fertile mvd_non_poor_infertile"
		
		plot_triple_diff, outcomes(``outcome_type'_outcome_vars') groups(`groups') design(income_fertility) ///
			stubs(``outcome_type'_stubs') event_date(`date_is_chpr') time(anio_qtr) ///
			weight(pesotri) city(mvd) city_legend(Montevideo) outcome_type_leg(`outcome_type')

		plot_triple_diff, outcomes(``outcome_type'_outcome_vars') groups(`groups') design(income_fertility) ///
			stubs(``outcome_type'_stubs') event_date(`sem_date_is_chpr') time(anio_sem) ///
			weight(pesosem) city(mvd) city_legend(Montevideo) outcome_type_leg(`outcome_type')
	
	}
end

program plot_triple_diff
	syntax, outcomes(str) groups(str) design(str) event_date(str) ///
	    stubs(str) time(str) weight(str) city(str) city_legend(str) ///
		outcome_type_leg(str) sample_restr(str) [special_legend(str)]
	
	if "`design'" == "income_gender" {
		local group_labels = `""Poor males" "Poor females" "Non-poor males" "Non-poor females""'
	}
	else {
		local group_labels = `" "Poor fertile" "Poor infertile" "Non-poor fertile" "Non-poor infertile" "'
	}
	
    local group1: word 1 of `groups' 
	local group2: word 2 of `groups' 
	local group3: word 3 of `groups' 
	local group4: word 4 of `groups' 

	local n_outcomes: word count `outcomes'
	local n_groups: word count `groups'
	
	forval i = 1/`n_outcomes' {
	    local outcome: word `i' of `outcomes'
	    local stub_var: word `i' of `stubs'
			use  ..\base\ech_final_98_2016.dta, clear 
	        keep if `group1' == 1 | `group2' == 1 | `group3' == 1 | `group4' == 1
			
	    forval j = 1/`n_groups' {
	        local group: word `j' of `groups'
			
			preserve
				collapse (mean) `outcome' [aw = `weight'] if `group' == 1 , by(`time')
				tsset `time'
				tssmooth ma `outcome' = `outcome', window(1 1 1) replace
				gen group = `j'
				save ../temp/group`j'_`outcome'_ts.dta, replace
			restore
			}
			use ../temp/group4_`outcome'_ts.dta, clear
			append using ../temp/group1_`outcome'_ts.dta
			append using ../temp/group2_`outcome'_ts.dta
			append using ../temp/group3_`outcome'_ts.dta		
				
			if "`time'" == "anio_qtr" {
				local range "if inrange(`time', tq(`event_date') - 12, tq(`event_date') + 12) "
				local xtitle "Year-qtr"
			}
			else {
				local range "if inrange(`time', th(`event_date') - 6, th(`event_date') + 6) "
				local xtitle "Year-half"
			}
            
			local group_label1: word 1 of `group_labels' 
			local group_label2: word 2 of `group_labels' 
			local group_label3: word 3 of `group_labels' 
			local group_label4: word 4 of `group_labels' 	
			
			qui twoway (line `outcome' `time' if group == 1) ///
				   (line `outcome' `time' if group == 2) ///
				   (line `outcome' `time' if group == 3) ///
				   (line `outcome' `time' if group == 4) `range', /// 
				   legend(label(1 "`group_label1'") label(2 "`group_label2'") ///
				   label(3 "`group_label3'") label(4 "`group_label4'")) ///
				   tline(`event_date', lcolor(black) lpattern(dot)) ///
				   graphregion(color(white)) bgcolor(white) xtitle("`xtitle'") ///
				   ytitle("`stub_var'") name(triple_diff_`outcome', replace) ///
				   title("`stub_var'", color(black) size(medium)) ylabel(#2)

	}

	forval i = 1/`n_outcomes' {
		local outcome: word `i' of `outcomes'
		local plots = "`plots' " + "triple_diff_`outcome'"
	}
		
	local plot1: word 1 of `plots' 	
	
	grc1leg `plots', rows(`n_outcomes') legendfrom(`plot1') position(6) /// /* cols(1) or cols(3) */
		   graphregion(color(white)) title({bf: `city_legend' `special_legend'}, color(black) size(small))
	graph display, ysize(8.5) xsize(6.5)
	graph export ../figures/triple_diff_`city'_`time'_`outcome_type_leg'_`design'.png, replace
end

main_triple_diff
