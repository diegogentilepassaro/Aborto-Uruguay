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
       use ..\temp\clean_1998.dta, clear
    
    forval year=1999/2016{
        append using ..\temp\clean_`year'.dta
    }
    replace anio = 1998 if anio == 98
    replace anio = 1999 if anio == 99
    replace anio = 2000 if anio == 0
    
    recode_dummies, vars(trabajo_1 hombre busca_trabajo)
    
    save_data ../output/clean_1998_2016, key(numero pers anio) replace
end

main_append_years
