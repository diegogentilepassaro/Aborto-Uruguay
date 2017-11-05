clear all
set more off

program main_triple_diff
	local outcome_vars   = "trabajo horas_trabajo educ_HS_or_more"
	local stub_list      = "Employment Hours-worked High-school"
	
	local date_is_chpr "2002q1"
	
	local sem_date_is_chpr "2002h1"
	
	use  ..\base\ech_final_98_2016.dta, clear 
	local groups "mvd_poor_male mvd_poor_female mvd_non_poor_male mvd_non_poor_female"
	local group_labels `" "Poor males" "Poor females" "Non-poor males" "Non-poor females" "'
    
	plot_triple_diff, outcomes(`outcome_vars') groups(`groups') group_labels(`group_labels') ///
	    stubs(`stub_list') event_date(`date_is_chpr') time(anio_qtr) ///
		weight(pesotri) city(mvd) city_legend(Montevideo)
end

program plot_triple_diff
	syntax, outcomes(str) groups(str) group_labels(str) event_date(str) ///
	    stubs(str) time(str) weight(str) city(str) city_legend(str)

    local group1: word 1 of `groups' 
	local group2: word 2 of `groups' 
	local group3: word 3 of `groups' 
	local group4: word 4 of `groups' 
	
	keep if `group1' == 1 | `group2' == 1 | `group3' == 1 | `group4' == 1

	local n_outcomes: word count `outcomes'
	local n_groups: word count `groups'
	
	forval i = 1/`n_outcomes' {
	    local outcome: word `i' of `outcomes'
	    local stub_var: word `i' of `stubs'
		
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
				   legend(label(1 "`group_label1'") label(2 "`group_label1'") ///
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
	graph export ../figures/triple_diff_`city'_`time'.png, replace
end

main_triple_diff
