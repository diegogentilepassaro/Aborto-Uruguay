clear all
set more off
adopath + ../../../library/stata/gslab_misc/ado

program main
	qui do ..\..\globals.do
	global controls = "nbr_people ind_under14 edad married poor"
	/*
	local outcomes     = "trabajo horas_trabajo"
	local data        = "ech"
	local time        = "anio_sem"
	local num_periods = "6"
	*/
	local labor_vars   = "trabajo horas_trabajo work_part_time"
	pooled_reg, outcomes(`labor_vars') data(ech_labor) time(anio_sem) num_periods(6)
	local educ_vars   = "educ_HS_diploma educ_some_college anios_secun anios_terc"
	pooled_reg, outcomes(`educ_vars') data(ech_educ) time(anio_sem) num_periods(6)
	pooled_reg, outcomes(births GFR) data(births_long) time(anio_sem) num_periods(6)
	pooled_reg, outcomes(lowbirthweight apgar1_low recomm_prenatal_numvisits preg_preterm) data(births_ind) time(anio_sem) num_periods(6)
end

program pooled_reg
    syntax, outcomes(str) data(str) time(str) num_periods(int)
 
	* Set locals
	if "`time'" == "anio_sem" {
		local weight pesosem
		local time_label "Semesters relative to IS implementation"
	}
	else {
		local weight pesoan
		local time_label "Years relative to IS implementation"
	}
	if substr("`data'",1,3) == "ech" {
		local all_controls = "c98_* ${controls}" //note: using all data, can't use c_0*
		local pweight = "[pw = `weight']"
		local cond_list "&!mi(dpto) &kids_before==1 &kids_before==0 &single==0 &single==1"  /*"& young == 0" "& young == 1"*/
		local age_group_list "_fertile _placebo"
	}
	else if "`data'" == "births_ind" {
		local all_controls = ""
		local pweight = ""
		local age_group_list "_fertile"
		local cond_list "&!mi(dpto) &kids_before==1 &kids_before==0 &single==0 &single==1"
	}
	else {
		local all_controls = ""
		local pweight = ""
		local age_group_list "_fertile"
		local cond_list "&all_sample==1 &kids_before==1 &kids_before==0 &single==0 &single==1"
	}
	*local omitted = `num_periods'+1 //tr_t = treatment*t
	
	* Run regressions	
	local n_outcomes: word count `outcomes'
	clear matrix
    forval i = 1/`n_outcomes' {
        local outcome: word `i' of `outcomes'

        use ../temp/plots_sample_`data'.dta, clear
        rename treatment treatment_fertile
        local lab_v`i' : variable label `outcome'
        local lab1_v`i': label (`outcome') 1
		
        if inlist("`outcome'","horas_trabajo","work_part_time")  {
            keep if trabajo==1
        }
        
		* Run main regression that plots coefficients
		/*reg `outcome' ib`omitted'.t##i.treatment i.`time' i.dpto  ///
				`all_controls' if !mi(treatment) & inrange(edad, 16, 45) ///
				`pweight', vce(cluster `time')*/

		* Run regressions by subsamples
		foreach cond in `cond_list' {
            
            foreach age_group in `age_group_list' {
				//local ES_subsample  = " if (treatment`age_group'==1 | (dpto==1 & age`age_group'==1)) "
				local DiD_subsample = " if !mi(treatment`age_group') "

				di "*** REG: `outcome' , `cond' , `age_group' ***"

				if inlist("`cond'","&!mi(dpto)","&all_sample==1") {
					//sum `outcome' `ES_subsample' `cond', meanonly
					//local avg_v`i'_ES`age_group' = r(mean)
					sum `outcome' `DiD_subsample' `cond', meanonly
					local avg_v`i'_DiD`age_group' = r(mean)
				}

            	/*reg `outcome' post i.dpto  ///
					`ES_subsample' `cond' `pweight', vce(cluster dpto)
				matrix COL_ES`age_group' = ((_b[post] \ _se[post]) \ e(N))*/

                gen interaction = treatment`age_group' * post

                reghdfe `outcome' i.treatment`age_group' i.post interaction ///
                    i.`time' i.dpto  `all_controls' ///
                    `DiD_subsample' `cond' `pweight', noabsorb cluster(`time' dpto)
		
                matrix COL_DiD`age_group' = ((_b[interaction] \ _se[interaction]) \ e(N))
        
                drop interaction
            }
			if substr("`data'",1,3) == "ech" {
				//matrix COL_ES  = (COL_ES_fertile,  COL_ES_placebo)
				matrix COL_DiD = (COL_DiD_fertile, COL_DiD_placebo)
			}
			else {
				//matrix COL_ES  = (COL_ES_fertile)
				matrix COL_DiD = (COL_DiD_fertile)
			}
            //matrix ROW_ES  = (nullmat(ROW_ES)  \ COL_ES)
            matrix ROW_DiD = (nullmat(ROW_DiD) \ COL_DiD)
		}
		*local stub = substr("`outcome'",1,10)
        //matrix TAB_ES  = (nullmat(TAB_ES) , ROW_ES)
        matrix TAB_DiD = (nullmat(TAB_DiD), ROW_DiD)
		matrix drop ROW_DiD //ROW_ES
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
    else if "`data'" == "ech_educ" {
		local cond2        = "Kids under 14"
		local cond3        = "No kids under 14"
		foreach rd in DiD { //ES
			file open myfile using "../output/tab_`rd'_`data'.txt", write replace
			file write myfile "\begin{threeparttable}" ///
							_n "\begin{tabular}{l|cc|cc|cc|cc} \hline\hline"  ///
							_n " & \multicolumn{2}{c|}{`lab_v1'} & \multicolumn{2}{c}{`lab_v2'} & \multicolumn{2}{c}{`lab_v3'} & \multicolumn{2}{c}{`lab_v4'} \\ \hline" ///
							_n " & (1)        & (2)        & (3)        & (4)        & (5)        & (6)        & (7)        & (8)  \\ "  ///
							_n " & Age: 16-45 & Age: 46-60 & Age: 16-45 & Age: 46-60 & Age: 16-45 & Age: 46-60 & Age: 16-45 & Age: 46-60 \\ \hline" ///
							_n "Mean (baseline) & " %9.3f (`avg_v1_`rd'_fertile') " & " %9.3f (`avg_v1_`rd'_placebo') " & " ///
							                        %9.3f (`avg_v2_`rd'_fertile') " & " %9.3f (`avg_v2_`rd'_placebo') " & " ///
							                        %9.3f (`avg_v3_`rd'_fertile') " & " %9.3f (`avg_v3_`rd'_placebo') " & " ///
							                        %9.3f (`avg_v4_`rd'_fertile') " & " %9.3f (`avg_v4_`rd'_placebo') " \\ \hline "
			local r = rowsof(TAB_`rd') / 3
			forvalues i = 1/`r' {
				local j1 = 3 * `i' - 2
				local j2 = 3 * `i' - 1
				local j3 = 3 * `i' 
				file write myfile ///
					_n "`cond`i'' &  " ///
						      %9.3f  (TAB_`rd'[`j1',1]) "  &  " %9.3f (TAB_`rd'[`j1',2]) " & " ///
                              %9.3f  (TAB_`rd'[`j1',3]) "  &  " %9.3f (TAB_`rd'[`j1',4]) " & " ///
                              %9.3f  (TAB_`rd'[`j1',5]) "  &  " %9.3f (TAB_`rd'[`j1',6]) " & " ///
                              %9.3f  (TAB_`rd'[`j1',7]) "  &  " %9.3f (TAB_`rd'[`j1',8]) " \\ " ///
                	_n " & (" %9.3f  (TAB_`rd'[`j2',1]) ") & (" %9.3f (TAB_`rd'[`j2',2]) ") & (" ///
                	    	  %9.3f  (TAB_`rd'[`j2',3]) ") & (" %9.3f (TAB_`rd'[`j2',4]) ") & (" ///
                	    	  %9.3f  (TAB_`rd'[`j2',5]) ") & (" %9.3f (TAB_`rd'[`j2',6]) ") & (" ///
                	    	  %9.3f  (TAB_`rd'[`j2',7]) ") & (" %9.3f (TAB_`rd'[`j2',8]) ") \\ " ///
               		_n " &  " %9.0fc (TAB_`rd'[`j3',1]) "  &  " %9.0fc (TAB_`rd'[`j3',2]) " & " ///
                		      %9.0fc (TAB_`rd'[`j3',3]) "  &  " %9.0fc (TAB_`rd'[`j3',4]) " & " ///
                		      %9.0fc (TAB_`rd'[`j3',5]) "  &  " %9.0fc (TAB_`rd'[`j3',6]) " & " ///
                		      %9.0fc (TAB_`rd'[`j3',7]) "  &  " %9.0fc (TAB_`rd'[`j3',8]) " \\ "
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
		
	/*matrix_to_txt, matrix(TAB_ES) saving("../output/tables.txt") append ///
		 title(<tab:es_pooled_`data'>)*/
	matrix_to_txt, matrix(TAB_DiD) saving("../output/tables.txt") append ///
		 title(<tab:did_pooled_`data'>)
end

main
