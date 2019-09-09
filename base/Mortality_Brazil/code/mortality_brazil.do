clear all
set more off
adopath + ../../../library/stata/gslab_misc/ado

program main
    import_brasil_data, file(mortality_w_fertile) geo_var(unidadedafederação)
    import_brasil_data, file(maternal_mortality) geo_var(unidadedafederação)
    import_brasil_data, file(tot_mortality_w_fertile) geo_var(região)
    import_brasil_data, file(tot_maternal_mortality) geo_var(região)    
    
    process_brasil_data
    save_data ../output/brasil_mm_data.dta, key(geo_unit year) replace    
end

program import_brasil_data
    syntax, file(str) geo_var(str)
 
    import delimited "../../../raw//`file'.csv", clear ///
        delimiter (";", collapse) varname(1)
    
    drop if missing(v2)
    
    rename `geo_var' geo_unit
    
    forval i = 2/22 {
        local year = 1994 + `i'
        local name  "`file'`year'"
        rename v`i' `name' 
    }
    
    reshape long `file', i(geo_unit) j(year)
    
    drop total
    
    save "../temp/`file'.dta", replace
 end
 
program process_brasil_data
    use "../temp/mortality_w_fertile.dta", clear
    merge 1:1 year geo_unit using "../temp/maternal_mortality.dta", ///
        assert(3) keep(3) nogen 
    replace geo_unit = "Rio Grande do Sul" if geo_unit == "43 Rio Grande do Sul"

    keep if geo_unit == "Rio Grande do Sul"
    gen mm_ratio = maternal_mortality / mortality_w_fertile
    save "../temp/rgds_mm_ratio.dta", replace
   
    use "../temp/tot_mortality_w_fertile.dta", clear
    merge 1:1 geo_unit year using "../temp/tot_maternal_mortality.dta", ///
        assert(3) keep(3) nogen 
    keep if geo_unit == "Total"
    replace geo_unit = "Brasil" if geo_unit == "Total"
    rename (tot_mortality_w_fertile tot_maternal_mortality) ///
        (mortality_w_fertile maternal_mortality)
    gen mm_ratio = maternal_mortality / mortality_w_fertile

    append using "../temp/rgds_mm_ratio.dta"
    
    encode geo_unit, gen(geo_unit_num)

    xtset geo_unit_num year

    tssmooth ma ma_mm_ratio  = mm_ratio, window(2 1 2)
    label var   ma_mm_ratio "Maternal mortality over fertile women's mortality"
    keep geo_unit year mm_ratio ma_mm_ratio
end

*EXECUTE
main
