clear all
set more off
adopath + ../../../library/stata/gslab_misc/ado

program main
    import_and_process_data
    save_data ../output/misoprostol.dta, key(region year) replace
end

program import_and_process_data
    import excel using "../../../raw/fernandez_misoprostol.xlsx", ///
        sheet("Sheet1") firstrow clear
        
    gen norm_sales2002 = 100
    gen norm_sales2007 = norm_sales2002 + perc
    gen sales_miso_only2002 = (sales_miso_only2007 * norm_sales2002) / norm_sales2007
    gen ug_per_pop2002 = sales_miso_only2002 / world_bank_pop2002
    gen ug_per_pop2007 = sales_miso_only2007 / world_bank_pop2007
    
    drop world_bank* sales_miso* perc
    
    reshape long norm_sales ug_per_pop, i(Region) j(year)
    
    rename Region region
    label var ug_per_pop "Misoprostol (in µg × 10^6) / Population (in millions)"
    label var year "Year"
end

*EXECUTE
main
