clear all
set more off
cd "C:\Users\dgentil1\Desktop\aborto_uru_repo\Aborto-Uruguay\raw"
*cd "C:\Users\cravizza\Google Drive\RIIPL\_PIW\abortion_UR\raw"

program main 
	append_person_years
end

program append_person_years
   	use ..\base\clean_1998_p.dta
	
	forval year=1999/2000 {
	    append using ..\base\clean_`year'_p.dta
	}
    isid numero pers anio
	
	save ..\base\clean_1998_2000_pers, replace
end

main
