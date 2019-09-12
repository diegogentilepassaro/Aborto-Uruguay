clear all
set more off
adopath + ../../../library/stata/gslab_misc/ado

program main 
    create_year_panel
end

program create_year_panel
    use ../../ECH/output/main_ECH_panel.dta, clear
    collapse (mean) share_women_public_health = public_health [aw = pesoan], by(anio dpto)

    merge 1:1 anio dpto using ../../../base/Aggregate_Births/output/by_year_dpto_aggregate_births.dta, ///
        nogen keepusing(nat_level nat_rate population)
    merge 1:1 anio dpto using ../../../base/Population/output/by_year_dpto_population.dta, ///
        nogen keepusing(women_pop fertile_women pop)
    save_data ../output/year_dpto_panel.dta, key(anio dpto) replace
end

* EXECUTE
main
