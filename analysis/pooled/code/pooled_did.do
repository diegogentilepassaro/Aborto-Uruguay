clear all
set more off
adopath + ../../../library/stata/gslab_misc/ado

program main
	qui do ..\..\globals.do
	global controls = "nbr_people ind_under14 edad married y_hogar_alt"
	/*
	local outcomes     = "trabajo horas_trabajo"
	local data        = "ech"
	local time        = "anio_sem"
	local geo_var     = "dpto"
	local num_periods = "6"
	local int_mvd     = "int_mvd"
	*/
	reg_did, outcomes(trabajo horas_trabajo) data(ech) time(anio_sem) geo_var(dpto) num_periods(6) int_mvd(int_mvd)
end

program reg_did
    syntax, outcomes(str) data(str) time(str) geo_var(str) num_periods(int) int_mvd(str) 
 
	if "`data'" == "ech" {
		use  ..\..\..\assign_treatment\output\ech_final_98_2016.dta, clear
		keep if hombre == 0 & inrange(horas_trabajo,0,100) //& inrange(edad, 16, 45) 
		tab trabajo,m
		local all_controls = "c98_* ${controls}" //note: using all data, can't use c_0*
	}
	else {
		local all_controls = ""
	}
	
	if "`int_mvd'" == "int_mvd" {		
		keep if !mi(impl_date_dpto) & !inlist(dpto,1) //drop Montevideo
	}
	else {
		keep if !mi(impl_date_dpto) & !inlist(dpto,1,3,16) //drop Montevideo, San Jose, and Canelones
	}
	
	if "`time'" == "anio_sem" {
		local weight pesosem
		gen post = (`time' >= hofd(impl_date_dpto))
		local time_label "Semesters"
	}
	else {
		local weight pesoan
		gen post = (`time' >= yofd(impl_date_dpto))
		local time_label "Years"
	}
	
	if "`data'" == "ech" {
		replace `weight' = int(`weight')
		local pweight = "[pw = `weight']"
	}
	else {
		local pweight = ""
	}
	
	relative_time, num_periods(`num_periods') time(`time') event_date(impl_date_dpto)
	tab t,m
	replace t = t+1 if t<1000
	local omitted = `num_periods'+1 //tr_t = treatment*t
	di "Omitted period: -1 (prior to implementation) or t=`omitted'."
	tab t,m
	tab dpto,m
	
	save ..\temp\did_reg_sample.dta, replace
	
	* Run regressions	
		local n_outcomes: word count `outcomes'
		clear matrix
        forval i = 1/`n_outcomes' {
            local outcome: word `i' of `outcomes'

            use ..\temp\did_reg_sample.dta, clear
			
            if "`outcome'" == "horas_trabajo" {
                keep if trabajo==1
            }
            if "`outcome'" == "trabajo" {
                local estimation = "logit" 
            }
            else {
                local estimation = "reg"
            }
            
			* Run main regression that plots coefficients
			`estimation' `outcome' ib`omitted'.t##i.treatment i.`time' i.`geo_var'  ///
					`all_controls' if !mi(treatment) & inrange(edad, 16, 45) ///
					`pweight', vce(cluster `time')

			* Run regressions by subsamples
			foreach cond in "" "& kids_before == 1" "& kids_before == 0" "& single == 0" "& single == 1" /*"& young == 0" "& young == 1"*/ {
                
                if "`cond'" == "" {
                    
                    gen interaction = treatment * post
                    
                    `estimation' `outcome' i.treatment i.post interaction ///
						i.`time' i.`geo_var'  `all_controls' ///
						if !mi(treatment) `cond' `pweight', vce(cluster `time')
            
                    matrix COLUMN_young   = ((_b[interaction] \ _se[interaction]) \ e(N))
                    matrix COLUMN_adult   = (. \ . \ .)
                    
                    drop interaction
                    
                    gen interaction = treatment_placebo * post
					
					`estimation' `outcome' i.treatment_placebo i.post interaction ///
						i.`time' i.`geo_var'  `all_controls' ///
						if !mi(treatment_placebo) `cond' `pweight', vce(cluster `time')
                       
                    matrix COLUMN_placebo = ((_b[interaction] \ _se[interaction]) \ e(N))
                   
                    drop interaction
                }
                else {
                    foreach age_group in "_young" "_adult" "_placebo" {

                        gen interaction = treatment`age_group' * post

                        `estimation' `outcome' i.treatment`age_group' i.post interaction ///
                            i.`time' i.`geo_var'  `all_controls' ///
                            if !mi(treatment`age_group') `cond' `pweight', vce(cluster `time')
    			
                        matrix COLUMN`age_group' = ((_b[interaction] \ _se[interaction]) \ e(N))
                
                        drop interaction
                    }
                }
    			
                matrix COLUMN = (COLUMN_young , COLUMN_adult, COLUMN_placebo)
                matrix ROW = (nullmat(ROW) \ COLUMN)
			}
            matrix TABLE = (nullmat(TABLE) , ROW)
			matrix drop ROW
			drop post
        }
			
		matrix_to_txt, matrix(TABLE) saving("../output/tables.txt") append ///
			 title(<tab:did_pooled_heterog>)
end

main
