clear all
set more off
adopath + ../../../library/stata/gslab_misc/ado

program main
    use ../temp/vital_birth_records.dta, clear

    sample_restrictions
    gen_vars    
    save ../temp/vital_birth_records.dta, replace
    create_main_panels
end

program sample_restrictions
    keep if inrange(edad, 16, 45)
    drop if inlist(dpto,20,99)
end

program gen_vars
    gen public_health = (tipoestab == 1)
    drop tipoestab
end

program create_main_panels
    use ../temp/vital_birth_records.dta, clear

    preserve
    keep if treated_or_control == 1
    drop treated_or_control control montevideo
    save_data ../output/main_vitals_panel.dta, key(birth_id) replace
    restore

    keep if montevideo == 1
    drop treated_or_control treated control montevideo
    save_data ../output/main_vitals_panel_mvd.dta, key(birth_id) replace
end

* EXECUTE
main
