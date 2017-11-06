clear all
set more off

program main_prepare_for_analysis 
	use ..\temp\clean_loc_1998_2016.dta, clear
	
	fix_2012_weights
	save ..\temp\clean_loc_1998_2016.dta, replace
	
	import excel ..\raw\inflation.xlsx, sheet("Sheet1") firstrow clear
	merge 1:m anio using ..\temp\clean_loc_1998_2016.dta, nogen ///
	    assert(1 3)keep(3)
	save ..\temp\clean_loc_1998_2016.dta, replace	
    impute_poverty_lines_pre06
	
	gen pobre = (y_hogar <= lp_06)
	gen indigente = (y_hogar <= li_06)
	gen hay_menores = (cantidad_personas > cantidad_mayores)

	label_vars
    save ..\temp\clean_loc_1998_2016.dta, replace	
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
	
	    local by_vars "loc_code cantidad_mayores cantidad_personas"
	
	    rename (lp_06 li_06) (lp_06_2 li_06_2)
	    collapse (mean) lp_06_2 li_06_2, by(`by_vars')
	
	    save ..\temp\poverty_`year'_imputed.dta, replace

	    use ..\temp\clean_loc_1998_2016.dta, clear

	    merge m:1 `by_vars' using ..\temp\poverty_`year'_imputed.dta, nogen
	    replace lp_06 = lp_06_2 if anio == `year'
	    replace li_06 = li_06_2 if anio == `year'
	
	    drop lp_06_2 li_06_2
		replace lp_06 = (lp_06 * cpi_2006)/100 if anio == `year'
		replace li_06 = (li_06 * cpi_2006)/100 if anio == `year'
	    save ..\temp\clean_loc_1998_2016.dta, replace

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
	label define educ_HS 0 "HS degree or less" 1 "More than HS diploma"
	label values educ_HS educ_HS
end

main_prepare_for_analysis
