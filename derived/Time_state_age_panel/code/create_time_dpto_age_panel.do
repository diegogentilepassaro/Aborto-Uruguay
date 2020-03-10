clear all
set more off
adopath + ../../../library/stata/gslab_misc/ado

program main 
    create_year_dpto_age_panel
end

program create_year_dpto_age_panel
    use ../../../base/Population/output/by_anio_dpto_agebin_fertile_women_population.dta, clear
    save_data ../output/year_dpto_age_panel.dta, key(anio dpto age_min) replace
end

* EXECUTE
main
