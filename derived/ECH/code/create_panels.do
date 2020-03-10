clear all
set more off
adopath + ../../../library/stata/gslab_misc/ado

program main
    create_main_panels
    create_placebo_men_panels
    create_placebo_infertile_panels
end    

program create_main_panels
    use ../temp/ECH_panel.dta, clear
    keep if inrange(edad, 15, 44)
    keep if hombre == 0

    preserve
    keep if treated_or_control == 1
    drop treated_or_control control montevideo
    save_data ../output/main_ECH_panel.dta, key(anio pers numero) replace
    restore

    keep if montevideo == 1
    drop treated_or_control treated control montevideo
    save_data ../output/main_ECH_panel_mvd.dta, key(anio pers numero) replace
end

program create_placebo_men_panels
    use ../temp/ECH_panel.dta, clear
    keep if inrange(edad, 15, 44)
    keep if hombre == 1

    preserve
    keep if treated_or_control == 1
    drop treated_or_control control montevideo
    save_data ../output/placebo_men_ECH_panel.dta, key(anio pers numero) replace
    restore

    keep if montevideo == 1
    drop treated_or_control treated control montevideo
    save_data ../output/placebo_men_ECH_panel_mvd.dta, key(anio pers numero) replace    
end

program create_placebo_infertile_panels
    use ../temp/ECH_panel.dta, clear
    keep if inrange(edad, 45, 60)
    keep if hombre == 0

    preserve
    keep if treated_or_control == 1
    drop treated_or_control control montevideo
    save_data ../output/placebo_infertile_ECH_panel.dta, key(anio pers numero) replace
    restore 

    keep if montevideo == 1
    drop treated_or_control treated control montevideo
    save_data ../output/placebo_infertile_ECH_panel_mvd.dta, key(anio pers numero) replace    
end

* EXECUTE
main
