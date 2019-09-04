clear all
set more off
adopath + ../../../library/stata/gslab_misc/ado

program main
    import excel ../../../raw/inflation.xlsx, sheet("Sheet1") firstrow clear
    save_data ../output/inflation_by_year.dta, key(anio) replace 
end 

* EXECUTE
main
