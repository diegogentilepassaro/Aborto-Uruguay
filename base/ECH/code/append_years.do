clear all
set more off
adopath + ../../../library/stata/gslab_misc/ado

program main_append_years
    append_years
end

program append_years
    use ..\temp\clean_2001.dta, clear
    
    forval year=2002/2015{
        append using ..\temp\clean_`year'.dta
    }
        
    save_data ..\output\clean_2001_2015, key(numero pers anio) replace
end

main_append_years
