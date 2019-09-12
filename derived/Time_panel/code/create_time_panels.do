clear all
set more off
adopath + ../../../library/stata/gslab_misc/ado

program main 
    create_year_panel
end

program create_year_panel
    use ../../ECH/output/main_ECH_panel.dta, clear
    collapse (mean) share_women_public_health = public_health [aw = pesoan], by(anio)

    merge 1:1 anio using ../../../base/Aggregate_Births/output/total_aggregate_births.dta, ///
        nogen keepusing(nat_level nat_rate population)
    merge 1:1 anio using ../../../base/Mortality_Brazil/output/brasil_mm_data.dta, ///
        nogen keepusing(mm_ratio ma_mm_ratio)
    rename (mm_ratio ma_mm_ratio) (mm_ratio_brazil ma_mm_ratio_brazil)
    merge 1:1 anio using ../../../base/Mortality_Uruguay/output/uruguay_mm_data.dta, ///
        nogen keepusing(mm_ratio ma_mm_ratio)
    merge 1:1 anio using ../../../base/Population/output/by_year_population.dta, ///
        nogen keepusing(women_pop fertile_women pop)
    save_data ../output/year_panel.dta, key(anio) replace
end

* EXECUTE
main
