clear all
set more off

program main_append_person_years
	append_person_years
end

program recode_dummies
syntax, vars(varlist) // trabajo estudiante
	foreach var in `vars' {
		replace `var'=. if `var'==0
		replace `var'=0 if `var'==2
	}
end

program append_person_years
   	use ..\base\clean_1998_p.dta, clear
	
	forval year=1999/2016{
	    append using ..\base\clean_`year'_p.dta
	}
	replace anio = 1998 if anio == 98
	replace anio = 1999 if anio == 99
	replace anio = 2000 if anio == 0
	
	* asserting basic properties: 
	* - that there are no missing departamentos in any year
	* - and the primary keys
	/*forval year=1999/2016{
	    unique dpto if anio == `year'
		local n = r(sum)
		assert `n' == 19
	}
	
	isid numero pers anio*/
	
	recode_dummies, vars(trabajo estudiante sexo busca_trabajo)
	
	save ..\base\clean_1998_2016_pers, replace
end

main_append_person_years
