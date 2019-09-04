clear all
set more off
adopath + ../../../library/stata/gslab_misc/ado

program main
    use ../temp/clean_loc_2001_2016.dta, clear
    
    fix_2012_weights, by_vars(loc_code edad hombre estrato segm y_hogar)
    
    add_cpi_2006
    impute_poverty_lines_pre06, by_vars(trimestre loc_code nbr_above14 nbr_people)
    
    gen_vars
    label_vars

    drop if (missing(numero) | missing(pers) | missing(anio))
    replace horas_trabajo = . if horas_trabajo > 100
    
    save_data ../output/clean_loc_2001_2016.dta, key(numero pers anio) replace    
end

program fix_2012_weights
    syntax, by_vars(str)
    keep if anio == 2013
    replace anio = 2012 
        
    rename (pesotri pesosem) (pesotri2 pesosem2)
    collapse (mean) pesotri pesosem, by(`by_vars')
    
    save ../temp/pesos_2012_imputed.dta, replace

    use ../temp/clean_loc_2001_2016.dta, clear

    merge m:1 `by_vars' using ../temp/pesos_2012_imputed.dta, nogen
    replace pesotri = pesotri2 if anio == 2012
    replace pesosem = pesosem2 if anio == 2012
    
    drop pesotri2 pesosem2
    save ../temp/clean_loc_2001_2016_fixed_weights.dta, replace
end

program add_cpi_2006
    use ../../../base/Inflation/output/inflation_by_year.dta, clear 
    merge 1:m anio using ../temp/clean_loc_2001_2016_fixed_weights.dta, nogen ///
        assert(1 3)keep(3)
    save ../temp/clean_loc_2001_2016_cpi.dta, replace
end

program impute_poverty_lines_pre06
    syntax, by_vars(str)
    keep if anio == 2006
    
    forval year=2001/2005 {
        replace anio = `year' 
    
        rename (lp_06 li_06) (lp_06_2 li_06_2)
        collapse (mean) lp_06_2 li_06_2, by(`by_vars')
    
        save ../temp/poverty_`year'_imputed.dta, replace

        use ../temp/clean_loc_2001_2016_cpi.dta, clear

        merge m:1 `by_vars' using ../temp/poverty_`year'_imputed.dta, nogen
        replace lp_06 = lp_06_2 if anio == `year'
        replace li_06 = li_06_2 if anio == `year'
    
        drop lp_06_2 li_06_2
        replace lp_06 = (lp_06 * cpi_2006)/100 if anio == `year'
        replace li_06 = (li_06 * cpi_2006)/100 if anio == `year'
        save ../temp/clean_loc_2001_2016_fixed.dta, replace
    }
end

program gen_vars
    gen poor       = (y_hogar <= lp_06)
    gen indigente   = (y_hogar <= li_06)
    gen ind_under14 = (nbr_under14>0)
    gen work_part_time = (horas_trabajo<32) if !mi(horas_trabajo) & trabajo==1
    
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
end

* EXECUTE
main
