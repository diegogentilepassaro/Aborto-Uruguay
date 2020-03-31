clear all
set more off
adopath + ../../library/stata/gslab_misc/ado

program main_prepare_for_analysis 
    use ../temp/clean_loc_1998_2016.dta, clear
    
    fix_2012_weights, by_vars(loc_code trimestre edad hombre)
    
    import excel ..\..\raw\inflation.xlsx, sheet("Sheet1") firstrow clear
    merge 1:m anio using ..\temp\clean_loc_1998_2016_fixed_weights.dta, nogen ///
        assert(1 3)keep(3)
    save ..\temp\clean_loc_1998_2016_fixed.dta, replace

    impute_poverty_lines_pre06
    gen poor       = (y_hogar_alt <= lp_06)
    gen indigente   = (y_hogar_alt <= li_06)
    
    gen ind_under14 = (nbr_under14>0)
    gen work_part_time = (horas_trabajo<32) if !mi(horas_trabajo) & trabajo==1
    
    gen     semestre = 1 if inlist(trimestre, 1, 2)
    replace semestre = 2 if inlist(trimestre, 3, 4)
    gen     anio_sem = yh(anio, semestre)
    format  anio_sem %th
    gen     anio_qtr = yq(anio, trimestre)
    format  anio_qtr %tq
     
    label_vars
    drop if (missing(numero) | missing(pers) | missing(anio))
    replace horas_trabajo = . if horas_trabajo >= 100
    save_data ../output/clean_loc_1998_2016.dta, key(numero pers anio) replace    
end

program fix_2012_weights
    syntax, by_vars(str)
    
    keep if anio == 2013
        
    rename (pesotri pesosem) (pesotri2 pesosem2)
    collapse (mean) pesotri2 pesosem2, by(`by_vars')
    gen anio = 2012
    
    save ../temp/pesos_2012_imputed.dta, replace

    use ../temp/clean_loc_1998_2016.dta, clear
    
    merge m:1 anio `by_vars' using ../temp/pesos_2012_imputed.dta, ///
        keepusing(pesosem2 pesotri2) keep(1 3)
    replace pesotri = pesotri2 if _merge == 3
    replace pesosem = pesosem2 if _merge == 3
    drop pesotri2 pesosem2 _merge
    
    save ../temp/clean_loc_1998_2016_fixed_weights.dta, replace
end

program impute_poverty_lines_pre06
    keep if anio == 2006
    
    forval year=1998/2005 {
        replace anio = `year' 
    
        local by_vars " trimestre loc_code nbr_above14 nbr_people"
    
        rename (lp_06 li_06) (lp_06_2 li_06_2)
        collapse (mean) lp_06_2 li_06_2, by(`by_vars')
    
        save ..\temp\poverty_`year'_imputed.dta, replace

        use ..\temp\clean_loc_1998_2016_fixed.dta, clear

        merge m:1 `by_vars' using ..\temp\poverty_`year'_imputed.dta, nogen
        replace lp_06 = lp_06_2 if anio == `year'
        replace li_06 = li_06_2 if anio == `year'
    
        drop lp_06_2 li_06_2
        replace lp_06 = (lp_06 * cpi_2006)/100 if anio == `year'
        replace li_06 = (li_06 * cpi_2006)/100 if anio == `year'
        save ..\temp\clean_loc_1998_2016_fixed.dta, replace
    }
end

program label_vars
    label var trabajo "Employment"
    label var horas_trabajo "Hours worked"
    label var work_part_time "Part-time work"
    label var anios_prim  "Years of primary school"
    label var anios_secun "Years of high school"
    label var anios_tecn  "Years of technical school"
    label var anios_terc  "Years of college"

    label var    educ_level "Educational attainment"
    label define educ_level 1 "Primary school" 2 "High school (incomplete)" 3 "High school (complete)" 4 "Post-secondary"
    label values educ_level educ_level
    
    gen       educ_anios_secun = anios_secun if !mi(anios_secun) & educ_level<4 & inrange(edad,16,22)
    label var educ_anios_secun "Years of high school"
    gen       educ_anios_terc  = anios_terc  if !mi(anios_terc) & educ_level>=3 & inrange(edad,18,30)
    label var educ_anios_terc  "Years of college"

    gen          educ_HS_diploma = (educ_level == 3) if !mi(educ_level) & educ_level<4 & inrange(edad,18,22)
    label var    educ_HS_diploma "High-school completed"
    label define educ_HS_diploma 0 "No HS diploma" 1 "HS diploma or more"
    label values educ_HS_diploma educ_diploma
    
    gen          educ_some_college = (educ_level == 4) if !mi(educ_level) & educ_level>=3 & inrange(edad,18,30)
    label var    educ_some_college "Some College"
    label define educ_some_college 0 "No College" 1 "Some College"
    label values educ_some_college educ_some_college
end

main_prepare_for_analysis
