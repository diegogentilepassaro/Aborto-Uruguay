clear all
set more off
adopath + ../../library/stata/gslab_misc/ado

program main_prepare_for_analysis 
	use ..\temp\clean_loc_1998_2016.dta, clear
	
	fix_2012_weights
	save ..\temp\clean_loc_1998_2016_fixed_weights.dta, replace
	
	import excel ..\..\raw\inflation.xlsx, sheet("Sheet1") firstrow clear
	merge 1:m anio using ..\temp\clean_loc_1998_2016_fixed_weights.dta, nogen ///
	    assert(1 3)keep(3)
	save ..\temp\clean_loc_1998_2016_fixed.dta, replace

    impute_poverty_lines_pre06
	gen poor       = (y_hogar_alt <= lp_06)
	gen indigente   = (y_hogar_alt <= li_06)
	
	gen ind_under14 = (nbr_under14>0)
	
	gen     semestre = 1 if inlist(trimestre, 1, 2)
	replace semestre = 2 if inlist(trimestre, 3, 4)
	gen     anio_sem = yh(anio, semestre)
	format  anio_sem %th
	gen     anio_qtr = yq(anio, trimestre)
    format  anio_qtr %tq

	/*local outcomes = "trabajo horas_trabajo"
	deseasonalize, outcomes(`outcomes')*/
	 
	label_vars
	drop if (missing(numero) | missing(pers) | missing(anio))
    save_data ..\output\clean_loc_1998_2016.dta, key(numero pers anio) replace	
end

program fix_2012_weights
	keep if anio == 2013
	replace anio = 2012 
	
	local by_vars "loc_code edad hombre estrato"
	
	rename (pesotri pesosem) (pesotri2 pesosem2)
	collapse (mean) pesotri pesosem, by(`by_vars')
	
	save ..\temp\pesos_2012_imputed.dta, replace

	use ..\temp\clean_loc_1998_2016.dta, clear

	merge m:1 `by_vars' using ..\temp\pesos_2012_imputed.dta, nogen
	replace pesotri = pesotri2 if anio == 2012
	replace pesosem = pesosem2 if anio == 2012
	
	drop pesotri2 pesosem2
end

program impute_poverty_lines_pre06
	keep if anio == 2006
	
	forval year=1998/2005 {
	    replace anio = `year' 
	
	    local by_vars " trimestre loc_code nbr_above14 nbr_people"
	
	    rename (lp_06 li_06) (lp_06_2 li_06_2)
	    collapse (mean) lp_06_2 li_06_2, by(`by_vars')
	
	    save ..\temp\poverty_`year'_imputed.dta, replace

	    use ..\temp\clean_loc_1998_2016_fixed.dta, clear

	    merge m:1 `by_vars' using ..\temp\poverty_`year'_imputed.dta, nogen
	    replace lp_06 = lp_06_2 if anio == `year'
	    replace li_06 = li_06_2 if anio == `year'
	
	    drop lp_06_2 li_06_2
		replace lp_06 = (lp_06 * cpi_2006)/100 if anio == `year'
		replace li_06 = (li_06 * cpi_2006)/100 if anio == `year'
	    save ..\temp\clean_loc_1998_2016_fixed.dta, replace
	}
end

program deseasonalize  
    syntax, outcomes(str)
	
	levelsof dpto, local(dptos)
	
	foreach outcome in `outcomes' {
		gen `outcome'_des = `outcome'
	}
	
	foreach dpto of local dptos {
		foreach outcome in `outcomes' {

			qui sum `outcome' if anio < 2004 & dpto == `dpto' [aw = pesotri]
			local mean = r(mean)
			
			reg `outcome' i.trimestre if anio < 2004 & dpto == `dpto' [aw = pesotri]
			predict p_`outcome', resid
			
			replace `outcome'_des = p_`outcome' + `mean' if anio < 2004 & dpto == `dpto'
			drop p_`outcome'
			
			qui sum `outcome' if anio >= 2004 & dpto == `dpto' [aw = pesotri]
			local mean = r(mean)
			
			reg `outcome' i.trimestre if anio >= 2004 & dpto == `dpto' [aw = pesotri]
			predict p_`outcome', resid
			
			replace `outcome'_des = p_`outcome' + `mean' if anio >= 2004 & dpto == `dpto'
			drop p_`outcome'	
		}
	}
end

program label_vars
    label var trabajo "Employment"
	label var horas_trabajo "Hours worked"
	label var  educ_level "Educational attainment"
	label define educ_level 1 "Primary school" 2 "High school" 3 "Post-secondary"
	label values educ_level educ_level
    
	gen educ_more_HS = (educ_level == 3)
	gen educ_HS_or_more = (educ_level == 2 | educ_level == 3 )
	
	label var  educ_more_HS "College"
	label var educ_HS_or_more "High-school"
	label define educ_HS_or_more 0 "HS degree or less" 1 "More than HS diploma"
	label values educ_HS_or_more educ_HS_or_more
end

main_prepare_for_analysis
