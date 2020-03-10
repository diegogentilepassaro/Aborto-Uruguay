clear all
set more off
adopath + ../../../library/stata/gslab_misc/ado

program main
    use ../temp/vital_birth_records.dta, clear

    sample_restrictions
    save_data ../output/births.dta, key(birth_id) replace
	
    preserve
    keep if treated_or_control == 1
    drop treated_or_control control montevideo pereira
    save_data ../output/births_treated_control.dta, key(birth_id) replace
    restore

    keep if montevideo == 1
    drop treated_or_control treated control montevideo
    save_data ../output/births_mvd.dta, key(birth_id) replace
end 

program sample_restrictions
    keep if inrange(edad, 15, 44)
    drop if inlist(dpto,20,99)
end

* EXECUTE
main
