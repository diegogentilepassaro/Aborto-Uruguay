clear all
set more off
adopath + ../../../library/stata/gslab_misc/ado

program main
	qui do ..\..\globals.do

	local labor_vars   = "trabajo horas_trabajo work_part_time"
	pooled_reg, outcomes(`labor_vars') ///
        controls("i.blanco i.poor i.car i.married i.public_health c.edad c.nbr_people c.nbr_under14") ///
	    data(ech_labor) time(anio_sem) num_periods(6)
	/*local educ_vars   = "educ_HS_diploma educ_anios_secun educ_some_college educ_anios_terc"
	pooled_reg, outcomes(`educ_vars') data(ech_educ) time(anio_sem) num_periods(6)*/
	pooled_reg, outcomes(births GFR) controls(" ") ///
	    data(births_long) time(anio_sem) num_periods(6)
	pooled_reg, outcomes(lowbirthweight apgar1_low recomm_prenatal_numvisits preg_preterm) ///
	    controls(" ") data(births_ind) time(anio_sem) num_periods(6)
end

program pooled_reg
    syntax, outcomes(str) controls(str) data(str) time(str) num_periods(int)
 
	* Set locals
	if "`time'" == "anio_sem" {
		local weight pesosem
		local time_label "Semesters relative to IS implementation"
	}
	else {
		local weight pesoan
		local time_label "Years relative to IS implementation"
	}
	if "`data'" == "ech_labor" {
		local aweight = "[aw = `weight']"
		local cond_list "&!mi(dpto) &kids_before==1 &kids_before==0 &single==0 &single==1"  /*"& young == 0" "& young == 1"*/
		local age_group_list "_fertile _placebo"
		use ../temp/fertile_infertile_ECH_panel.dta, clear
    }
	else if "`data'" == "births_ind" {
		local aweight = ""
		local age_group_list "_fertile"
		local cond_list "&!mi(dpto) &kids_before==1 &kids_before==0 &single==0 &single==1"
		use ../temp/plots_sample_births_ind.dta, clear
	}
	else {
		local aweight = ""
		local age_group_list "_fertile"
		local cond_list "&all_sample==1 &kids_before==1 &kids_before==0 &single==0 &single==1"
		use ../temp/plots_sample_births_long.dta, clear
	}
	
	* Run regressions	
	local n_outcomes: word count `outcomes'
	clear matrix
    forval i = 1/`n_outcomes' {
        local outcome: word `i' of `outcomes'
        
        local lab_v`i' : variable label `outcome'
        local lab1_v`i': label (`outcome') 1
		
        if inlist("`outcome'","horas_trabajo","work_part_time")  {
            keep if trabajo==1
        }

		* Run regressions by subsamples
		foreach cond in `cond_list' {
            
            foreach age_group in `age_group_list' {
				local DiD_subsample = " if !mi(treatment`age_group') "

				di "*** REG: `outcome' , `cond' , `age_group' ***"

				if inlist("`cond'","&!mi(dpto)","&all_sample==1") {
					sum `outcome' `DiD_subsample' `cond', meanonly
					local avg_v`i'_DiD`age_group' = r(mean)
				}

                gen interaction = treatment`age_group' * post_`time'

                reghdfe `outcome' i.treatment`age_group' i.post_`time' interaction ///
                    i.`time' i.dpto  `all_controls' ///
                    `DiD_subsample' `cond' `aweight', noabsorb cluster(`time' dpto)
		
                matrix COL_DiD`age_group' = ((_b[interaction] \ _se[interaction]) \ e(N))
        
                drop interaction
            }
			if "`data'" == "ech_labor" {
				matrix COL_DiD = (COL_DiD_fertile, COL_DiD_placebo)
			}
			else {
				matrix COL_DiD = (COL_DiD_fertile)
			}
            matrix ROW_DiD = (nullmat(ROW_DiD) \ COL_DiD)
		}
        matrix TAB_DiD = (nullmat(TAB_DiD), ROW_DiD)
		matrix drop ROW_DiD 
    }

	local cond1            = "Baseline"
	local cond4            = "Not single"
	local cond5            = "Single"
    if "`data'" == "ech_labor" {
		local cond2        = "Kids under 14"
		local cond3        = "No kids under 14"
		foreach rd in DiD { //ES
			file open myfile using "../output/tab_`rd'_`data'.txt", write replace
			file write myfile "\begin{threeparttable}" ///
							_n "\begin{tabular}{l|cc|cc|cc} \hline\hline"  ///
							_n " & \multicolumn{2}{c|}{`lab_v1'} & \multicolumn{2}{c}{`lab_v2'} & \multicolumn{2}{c}{`lab_v3'} \\ \hline" ///
							_n " & (1)        & (2)        & (3)        & (4)        & (5)        & (6)  \\ "  ///
							_n " & Age: 16-45 & Age: 46-60 & Age: 16-45 & Age: 46-60 & Age: 16-45 & Age: 46-60 \\ \hline" ///
							_n "Mean (baseline) & " %9.3f (`avg_v1_`rd'_fertile') " & " %9.3f (`avg_v1_`rd'_placebo') " & " ///
							                        %9.3f (`avg_v2_`rd'_fertile') " & " %9.3f (`avg_v2_`rd'_placebo') " & " ///
							                        %9.3f (`avg_v3_`rd'_fertile') " & " %9.3f (`avg_v3_`rd'_placebo') " \\ \hline "
			local r = rowsof(TAB_`rd') / 3
			forvalues i = 1/`r' {
				local j1 = 3 * `i' - 2
				local j2 = 3 * `i' - 1
				local j3 = 3 * `i' 
				file write myfile ///
					_n "`cond`i'' &  " ///
						      %9.3f  (TAB_`rd'[`j1',1]) "  &  " %9.3f (TAB_`rd'[`j1',2]) " & " ///
                              %9.3f  (TAB_`rd'[`j1',3]) "  &  " %9.3f (TAB_`rd'[`j1',4]) " & " ///
                              %9.3f  (TAB_`rd'[`j1',5]) "  &  " %9.3f (TAB_`rd'[`j1',6]) " \\ " ///
                	_n " & (" %9.3f  (TAB_`rd'[`j2',1]) ") & (" %9.3f (TAB_`rd'[`j2',2]) ") & (" ///
                	    	  %9.3f  (TAB_`rd'[`j2',3]) ") & (" %9.3f (TAB_`rd'[`j2',4]) ") & (" ///
                	    	  %9.3f  (TAB_`rd'[`j2',5]) ") & (" %9.3f (TAB_`rd'[`j2',6]) ") \\ " ///
               		_n " &  " %9.0fc (TAB_`rd'[`j3',1]) "  &  " %9.0fc (TAB_`rd'[`j3',2]) " & " ///
                		      %9.0fc (TAB_`rd'[`j3',3]) "  &  " %9.0fc (TAB_`rd'[`j3',4]) " & " ///
                		      %9.0fc (TAB_`rd'[`j3',5]) "  &  " %9.0fc (TAB_`rd'[`j3',6]) " \\ "
			}
			file write myfile _n "\hline\hline" _n "\end{tabular}" 
			file close myfile
		}	
	}
    else if "`data'" == "births_ind" {
		local cond2 = "Had previous pregnancy"
		local cond3 = "First pregnancy"
		foreach rd in DiD { //ES
			file open myfile using "../output/tab_`rd'_`data'.txt", write replace
			file write myfile "\begin{threeparttable}" ///
							_n "\begin{tabular}{l|cccc} \hline\hline"  ///
							_n " & `lab1_v1' & `lab1_v2' & `lab1_v3' & `lab1_v4' \\ \hline" ///
							_n " & (1)       & (2)       & (3)       & (4)       \\ \hline" ///
							_n "Mean (baseline) & " %9.3f (`avg_v1_`rd'_fertile') " & " %9.3f (`avg_v2_`rd'_fertile') ///
							                  " & " %9.3f (`avg_v3_`rd'_fertile') " & " %9.3f (`avg_v4_`rd'_fertile') " \\ \hline "
			local r = rowsof(TAB_`rd') / 3
			forvalues i = 1/`r' {
				local j1 = 3 * `i' - 2
				local j2 = 3 * `i' - 1
				local j3 = 3 * `i' 
				file write myfile ///
					_n "`cond`i'' &  " ///
						      %9.3f  (TAB_`rd'[`j1',1]) "  &  " %9.3f (TAB_`rd'[`j1',2]) " & " ///
                              %9.3f  (TAB_`rd'[`j1',3]) "  &  " %9.3f (TAB_`rd'[`j1',4]) " \\ " /// 
                	_n " & (" %9.3f  (TAB_`rd'[`j2',1]) ") & (" %9.3f (TAB_`rd'[`j2',2]) ") & (" ///
                	    	  %9.3f  (TAB_`rd'[`j2',3]) ") & (" %9.3f (TAB_`rd'[`j2',4]) ") \\ " ///
               		_n " &  " %9.0fc (TAB_`rd'[`j3',1]) "  &  " %9.0fc (TAB_`rd'[`j3',2]) " & " ///
                		      %9.0fc (TAB_`rd'[`j3',3]) "  &  " %9.0fc (TAB_`rd'[`j3',4])  " \\ " 
			}
			file write myfile _n "\hline\hline" _n "\end{tabular}" 
			file close myfile
		}		
	}
	else {
		local cond2 = "Had previous pregnancy"
		local cond3 = "First pregnancy"
		foreach rd in DiD { //ES
			file open myfile using "../output/tab_`rd'_`data'.txt", write replace
			file write myfile "\begin{threeparttable}" ///
							_n "\begin{tabular}{l|cc} \hline\hline"  ///
							_n " & `lab_v1' & Fertility rate \\ \hline"  ///
							_n "Mean & " %9.3f (`avg_v1_`rd'_fertile') " & " %9.3f (`avg_v2_`rd'_fertile') " \\ \hline "
			local r = rowsof(TAB_`rd') / 3
				forvalues i = 1/`r' {
					local j1 = 3 * `i' - 2
					local j2 = 3 * `i' - 1
					local j3 = 3 * `i' 
					file write myfile ///
						_n "`cond`i'' &  " %9.3f  (TAB_`rd'[`j1',1]) "  &  " %9.3f  (TAB_`rd'[`j1',2]) " \\ " ///
		                _n "          & (" %9.3f  (TAB_`rd'[`j2',1]) ") & (" %9.3f  (TAB_`rd'[`j2',2]) ") \\ " ///
		               	_n "          &  " %9.0fc (TAB_`rd'[`j3',1]) "  &  " %9.0fc (TAB_`rd'[`j3',2]) " \\ "
		        }
			file write myfile _n "\hline\hline" _n "\end{tabular}" 
			file close myfile
		}
	}

	matrix_to_txt, matrix(TAB_DiD) saving("../output/tables.txt") append ///
		 title(<tab:did_pooled_`data'>)
end

main
