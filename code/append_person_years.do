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
   isid numero pers anio
	
	save ..\base\clean_1998_2016_pers, replace
end

main_append_person_years
