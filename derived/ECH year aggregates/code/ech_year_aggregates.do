clear all
set more off
adopath + ../../../library/stata/gslab_misc/ado

program main 
    use ../../ECH/output/main_ECH_panel.dta, clear

    collapse (mean) share_women_public_health = public_health if hombre == 0 [aw = pesotri], by(anio_qtr)
    save_data ../output/ech_year_aggregates.dta, key(anio_qtr) replace    
end

* EXECUTE
main
