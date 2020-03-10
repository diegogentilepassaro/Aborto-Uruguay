clear all
set more off
adopath + ../../../library/stata/gslab_misc/ado

program main
    use ../temp/clean_loc_2001_2015.dta, clear
    
    fix_2012_weights, by_vars(loc_code trimestre edad hombre)
    
    add_cpi_2006
    impute_poverty_lines_pre06, by_vars(trimestre loc_code nbr_above14 nbr_people)

    sample_restrictions
    gen_and_modify_vars
    label_vars

    keep numero pers anio anio_sem anio_qtr semestre trimestre mes ///
        dpto loc_code ccz hombre edad blanco poor public_health married ///
        single y_hogar nbr_people nbr_under14 piped_water toilet sewage ///
        stove hot_water refrigerat tv car computer internet ///
        trabajo estudiante horas_trabajo work_part_time ///
        young adult fertile infertile kids_before pesoan pesosem pesotri
    order numero pers anio anio_sem anio_qtr semestre trimestre mes ///
        dpto loc_code ccz hombre edad blanco poor public_health married ///
        single y_hogar nbr_people nbr_under14 piped_water toilet sewage ///
        stove hot_water refrigerat tv car computer internet ///
        trabajo estudiante horas_trabajo work_part_time ///
        young adult fertile infertile kids_before pesoan pesosem pesotri

    save_data ../temp/clean_loc_2001_2015_with_vars.dta, key(numero pers anio) replace
end

program fix_2012_weights
    syntax, by_vars(str)
    
	keep if anio == 2013
    	
    rename (pesotri pesosem) (pesotri2 pesosem2)
    collapse (mean) pesotri2 pesosem2, by(`by_vars')
    gen anio = 2012
	
    save ../temp/pesos_2012_imputed.dta, replace

    use ../temp/clean_loc_2001_2015.dta, clear
	
    merge m:1 anio `by_vars' using ../temp/pesos_2012_imputed.dta, ///
	    keepusing(pesosem2 pesotri2) keep(1 3)
    replace pesotri = pesotri2 if _merge == 3
    replace pesosem = pesosem2 if _merge == 3
    drop pesotri2 pesosem2
    
    save ../temp/clean_loc_2001_2016_fixed_weights.dta, replace
end

program add_cpi_2006
    use ../../../base/Inflation/output/inflation_by_year.dta, clear 
    merge 1:m anio using ../temp/clean_loc_2001_2016_fixed_weights.dta, nogen ///
        assert(1 3)keep(3)
    save ../temp/clean_loc_2001_2015_cpi.dta, replace
end

program impute_poverty_lines_pre06
    syntax, by_vars(str)
    keep if anio == 2006
    
    forval year=2001/2005 {
        replace anio = `year' 
    
        rename lp_06 lp_06_2
        collapse (mean) lp_06_2, by(`by_vars')
    
        save ../temp/poverty_`year'_imputed.dta, replace

        use ../temp/clean_loc_2001_2015_cpi.dta, clear

        merge m:1 `by_vars' using ../temp/poverty_`year'_imputed.dta, nogen
        replace lp_06 = lp_06_2 if anio == `year'
    
        drop lp_06_2
        replace lp_06 = (lp_06 * cpi_2006)/100 if anio == `year'
        save ../temp/clean_loc_2001_2016_fixed.dta, replace
    }
end

program sample_restrictions
    keep if inrange(edad, 15, 60)
end

program gen_and_modify_vars
    replace horas_trabajo = . if horas_trabajo > 100
    replace nbr_people = . if (nbr_people < nbr_under14)
    replace nbr_under14 = . if (nbr_people < nbr_under14)
	gen kids_before = (nbr_under14 > 0) if !missing(nbr_under14)

    gen single      = (married==0)            if !mi(married)
	
    gen poor       = (y_hogar <= lp_06)
    gen ind_under14 = (nbr_under14>0)
    gen work_part_time = (horas_trabajo<32) if !mi(horas_trabajo) & trabajo==1

    assert !mi(edad)
    gen yob = anio - edad
    gen young   = inrange(edad,15,30)
    gen adult   = inrange(edad,31,44)
    gen infertile = inrange(edad,45,60)
    gen fertile = inrange(edad,15,44)
    
    gen     semestre = 1 if inlist(trimestre, 1, 2)
    replace semestre = 2 if inlist(trimestre, 3, 4)
    gen     anio_sem = yh(anio, semestre)
    format  anio_sem %th
    gen     anio_qtr = yq(anio, trimestre)
    format  anio_qtr %tq
end

program label_vars
    label var trabajo "Employment"
    label var horas_trabajo "Hours worked"
    label var work_part_time "Part-time work"
    
    lab def young                 0 "Age: 31-44"             1 "Age: 15-30"
    lab val young                 age_young    
end

* EXECUTE
main
