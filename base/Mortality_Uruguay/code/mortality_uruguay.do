clear all
set more off
adopath + ../../../library/stata/gslab_misc/ado

program main
    import_and_process_uruguay_data
    save_data "../output/uruguay_mm_data.dta", key(geo_unit year) replace
end

program import_and_process_uruguay_data
    import excel using "../../../raw/Cuadro 7. Mortalidad Materna 1900-2015.xlsx", clear cellrange(a9:h125) firstrow
    rename Año year
    label var year "Year"
    keep if year>=1985
    gen geo_unit = "Uruguay"
    
    gen mm_ratio = Cifras/Muertesdemujeres

    tsset year

    tssmooth ma ma_muertes = MuertesMaternas, window(2 1 2) //5-year average
    tssmooth ma ma_razon   = Raz, window(2 1 2) //5-year average
    tssmooth ma ma_mm_ratio  = mm_ratio, window(2 1 2)
    label var   ma_mm_ratio "Maternal mortality over fertile women's mortality"

    keep geo_unit year mm_ratio ma_mm_ratio
end

*EXECUTE
main
