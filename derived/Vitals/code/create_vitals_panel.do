clear all
set more off
adopath + ../../../library/stata/gslab_misc/ado

program main 
    use ../../../base/ECH/output/clean_2001_2015, clear
    

    save_data ../temp/clean_loc_2001_2015.dta, key(numero pers anio) replace    
end

* EXECUTE
main
