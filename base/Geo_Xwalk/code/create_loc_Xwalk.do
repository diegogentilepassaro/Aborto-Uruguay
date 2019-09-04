clear all
set more off
adopath + ../../../library/stata/gslab_misc/ado

program main 
    import excel ../../../raw/lista_homogen_codes_geo.xlsx, sheet("Sheet1") ///
        cellrange(B1:F100) firstrow clear
    rename (codigodpto localidad codigo98_2005 codigo_2006_2011 codigo_2012_2014) ///
        (dpto nomloc2 loc98_05 loc loc12_14)
    save_data ../output/loc_xwalk.dta, key(dpto loc) replace
end

* EXECUTE
main
