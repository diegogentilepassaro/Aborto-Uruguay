clear all
set more off

program main_append_person_years
	append_person_years
end

program append_person_years
   	use ..\base\clean_1998_p.dta
	
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
	
	*Recordatorio: 2012 only has pesoan but not pesotri or pesomes. We should either ask for them or impute using other years. 

	save ..\base\clean_1998_2016_pers, replace
end

main_append_person_years
