clear all
set more off
adopath + ../../library/stata/gslab_misc/ado

program main_append_years
	append_years
end

program recode_dummies
syntax, vars(varlist)
	foreach var in `vars' {
		replace `var'=0 if `var'==2
	}
end

program append_years
   	use ..\temp\clean_2001.dta, clear
	
	forval year=2002/2016{
	    append using ..\temp\clean_`year'.dta
	}
	
	* asserting basic properties: 
	* - that there are no missing departamentos in any year
	* - and the primary keys
	/*forval year=2001/2016{
	    unique dpto if anio == `year'
		local n = r(sum)
		assert `n' == 19
	}
	
	isid numero pers anio*/
	
	recode_dummies, vars(trabajo_1 hombre busca_trabajo)
	
	save_data ..\output\clean_2001_2016, key(numero pers anio) replace
end

main_append_years
