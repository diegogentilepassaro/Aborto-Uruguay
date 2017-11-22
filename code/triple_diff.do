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
	
		foreach design in poor_lowed  /*OK: poor_single*/ /*Opp: poor_lowed female_lowed female_single*/ /*NOT: lowed_single female_poor*/ {
				
			plot_triple_diff, outcomes(``group_vars'_vars') var1(female) var2(lowed) ///
				time(anio_sem) event_date(`s_date_mvd') city(mvd) city_legend(Montevideo) ///
				stubs(``group_vars'_stubs') groups_vars(`group_vars') plot_option(trend)
				
			/*plot_triple_diff, outcomes(``group_vars'_vars') design(`design') ///
				time(anio) event_date(`y_date_mvd') city(mvd) city_legend(Montevideo) ///
				stubs(``group_vars'_stubs') groups_vars(`group_vars') plot_option(trend)*/
				
			reg_triple_diff, outcomes(``group_vars'_vars') var1(female) var2(lowed) city(mvd) ///
				time(anio_sem) event_date(`s_date_mvd') groups_vars(`group_vars')
				
			/*reg_triple_diff, outcomes(``group_vars'_vars') design(`design') city(mvd) ///
				time(anio) event_date(`y_date_mvd') groups_vars(`group_vars')*/
		}			
	}
end

program plot_triple_diff
	syntax, outcomes(str) var1(str) var2(str) event_date(str) ///
	    stubs(str) time(str) city(str) city_legend(str) ///
		groups_vars(str) [plot_option(str) special_legend(str) sample_restr(str)]
	
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
		
	if "`var1'" == "female" | "`var2'" == "female" {
            local sample = "dpto == 1 "
        }
        else {
            local sample = "dpto == 1 & female == 1 "
        }
    
    forvalues i=1/2 {
        if          "`var`i''" == "female" {
                local var`i'lab = "Female"
                local var`i'opp = "Male"
            }
            else if "`var`i''" == "poor" {
                local var`i'lab = "Poor"
                local var`i'opp = "Rich"
            }
            else if "`var`i''" == "single" {
                local var`i'lab = "Single"
                local var`i'opp = "Married"                
            }
            else if "`var`i''" == "lowed" {
                local var`i'lab = "Low-educ"
                local var`i'opp = "High-educ"                
            }
    }
        
    local diff1 = "`var1lab': `var2lab' vs `var2opp'"
    local diff2 = "`var1opp': `var2lab' vs `var2opp'"
    
    local group_lab1 = "`var1lab' `var2lab'"
    local group_lab2 = "`var1lab' `var2opp'"
    local group_lab3 = "`var1opp' `var2lab'" 
    local group_lab4 = "`var1opp' `var2opp'"
    
	local n_outcomes: word count `outcomes'
	
	forval i = 1/`n_outcomes' {
	    local outcome : word `i' of `outcomes'
	    local stub_var: word `i' of `stubs'
		local plots = " `plots' " + "triple_diff_`outcome'"
		
		use  ..\base\ech_final_98_2016.dta, clear 
	
		gen group1 = (`sample' & `var1'==1 & `var2' ==1)
		gen group2 = (`sample' & `var1'==1 & `var2' ==0)
		gen group3 = (`sample' & `var1'==0 & `var2' ==1)
		gen group4 = (`sample' & `var1'==0 & `var2' ==0)
		
		keep if inrange(edad, 16, 45)
		keep if group1 == 1 | group2 == 1 | group3 == 1 | group4 == 1	
			
	    if "`plot_option'" == "diff" {
			forval j = 1/4 {
				preserve
					collapse (mean) `outcome' [aw = `weight'] if group`j' == 1 , by(`time')
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
			gen `outcome'_diff2 = `outcome'_3 - `outcome'_4

			qui twoway (scatter `outcome'_diff1 `time', c(l) lc(blue) mc(blue)) /// 
                       (scatter `outcome'_diff2 `time', c(l) lc(red)  mc(red)) ///                
                `range' , ///
                legend(on order(1 2) label(1 "`diff1'") label(2 "`diff2'") col(1) row(2)) ///
                tline(`event_date', lc(black) lp(dot)) title("`stub_var'", c(black) size(vlarge)) ///
                xtitle("`xtitle'", size(vlarge)) ytitle("`stub_var'", size(large)) ///
				xlabel(, labs(large)) ylabel(#2, labs(large)) ///
                graphregion(color(white)) bgcolor(white) name(triple_diff_`outcome', replace)
			
		}
		else {
			forval j = 1/4 {
				preserve
					collapse (mean) `outcome' [aw = `weight'] if group`j' == 1 , by(`time')
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
				
			 qui twoway (scatter `outcome' `time' if group == 1, c(l) lc(blue) mc(blue) ms(triangle)) ///
                        (scatter `outcome' `time' if group == 2, c(l) lc(red)  mc(red)  ms(triangle)) ///
                        (scatter `outcome' `time' if group == 3, c(l) lc(blue) mc(blue)) ///
                        (scatter `outcome' `time' if group == 4, c(l) lc(red)  mc(red)) ///
                `range', ///
                legend(on order (1 2 3 4) col(2) label(1 "`group_lab1'") label(2 "`group_lab2'") ///
                label(3 "`group_lab3'") label(4 "`group_lab4'") size(large)) ///
                tline(`event_date', lc(black) lp(dot)) title("`stub_var'", c(black) size(vlarge)) ///
                xtitle("`xtitle'", size(vlarge)) ytitle("`stub_var'", size(vlarge)) ///
				xlabel(, labs(large)) ylabel(#2, labs(large)) ///
                graphregion(color(white)) bgcolor(white) name(triple_diff_`outcome', replace)
		}
	}

	local plot1: word 1 of `plots' 	
	
	grc1leg `plots', rows(`n_outcomes') legendfrom(`plot1') position(6) cols(2) /// /* cols(1) or cols(3) */
		   graphregion(color(white)) title({bf: `city_legend' `special_legend'}, color(black) size(vlarge))
	graph display, ysize(3) xsize(7)
	graph export ../figures/triple_diff_`city'_`time'_`groups_vars'_`design'`plot_option'.png, replace
end

program reg_triple_diff
    syntax, outcomes(string) var1(str) var2(str) city(str) groups_vars(str) time(str) event_date(str)
	
	use  ..\base\ech_final_98_2016.dta, clear
	keep if inrange(edad, 16, 45)
	
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
			local range "if inrange(`time', th(`event_date') - 8,th(`event_date') + 4) "
			qui sum `time' `range'	
			local min_year = year(dofh(r(min)))
		}
		else {
			local weight pesoan
			gen post = (`time' >= `event_date')
			local range "if inrange(`time', `event_date' - 4, `event_date' + 2) "
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
	
	if "`var1'" == "female" | "`var2'" == "female" {
            local sample = "dpto == 1 "
        }
        else {
            local sample = "dpto == 1 & female == 1 "
        }
	
	forvalues i=1/2 {
        if          "`var`i''" == "female" {
                local var`i'lab = "Female"
            }
            else if "`var`i''" == "poor" {
                local var`i'lab = "Poor"
            }
            else if "`var`i''" == "single" {
                local var`i'lab = "Single"             
            }
            else if "`var`i''" == "lowed" {
                local var`i'lab = "Low-educ"              
            }
    }
	
	gen group1 = (`sample' & `var1'==1 & `var2' ==1)
	gen group2 = (`sample' & `var1'==1 & `var2' ==0)
	gen group3 = (`sample' & `var1'==0 & `var2' ==1)
	gen group4 = (`sample' & `var1'==0 & `var2' ==0)
	
	keep if group1 == 1 | group2 == 1 | group3 == 1 | group4 == 1
		
	local event = "`var1lab' x `var2lab'"
	gen int_no_post = `var1' * `var2'
	gen int_post1   = `var1' * post
	gen int_post2   = `var2' * post   
	gen int_triple = int_no_post * post
 
	local n_outcomes: word count `outcomes'
	forval i = 1/`n_outcomes' {
		local outcome: word `i' of `outcomes'
		
		eststo: reg `outcome' `var1' `var2' i.post int_* ///
					i.`time' cantidad_personas hay_menores edad married ///
					y_hogar_alt `control_vars' `range' [aw = `weight'], vce(cluster `time')
		}
		esttab using ../tables/triple_diff_`city'_`time'_`groups_vars'_`var1'_`var2'.tex, label se ar2 compress ///
			replace nonotes coeflabels(int_triple "`event' x Post") keep(int_triple) ///
			star(* 0.1 ** 0.05 *** 0.01)
		eststo clear
end

main_triple_diff
