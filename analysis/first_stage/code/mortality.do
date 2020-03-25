clear all
set more off

program main
    import_brasil_data, file(mortality_w_fertile) geo_var(unidadedafederação)
    import_brasil_data, file(maternal_mortality) geo_var(unidadedafederação)
    import_brasil_data, file(tot_mortality_w_fertile) geo_var(região)
    import_brasil_data, file(tot_maternal_mortality) geo_var(região)	
    
    process_brasil_data

    import_and_process_uruguay_data

    use "..\temp\brasil_mm_data.dta", clear
    append using "..\temp\uruguay_mm_data.dta"    
    
    plot_ratio, var_ratio(ma_mm_ratio) start_yr(1998) ///
	    end_yr(2014) tline(2003.5 2011.5)
    plot_ratio, var_ratio(mm_ratio) start_yr(1996) ///
	    end_yr(2016) tline(2003.5 2011.5)

    gen post = (year > 2003)
	gen treatment = (geo_unit == "Uruguay")
	did_reg, var_ratio(ma_mm_ratio)
	did_reg, var_ratio(mm_ratio)
end

program import_brasil_data
    syntax, file(str) geo_var(str)
 
    import delimited "..\..\..\raw\\`file'.csv", clear ///
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
    
    save "..\temp\\`file'.dta", replace
 end
 
program process_brasil_data
    use "..\temp\mortality_w_fertile.dta", clear
    merge 1:1 year geo_unit using "../temp/maternal_mortality.dta", ///
        assert(3) keep(3) nogen 
    replace geo_unit = "Rio Grande do Sul" if geo_unit == "43 Rio Grande do Sul"

    keep if geo_unit == "Rio Grande do Sul"
    gen mm_ratio = maternal_mortality / mortality_w_fertile
    save "..\temp\rgds_mm_ratio.dta", replace
   
    use "..\temp\tot_mortality_w_fertile.dta", clear
    merge 1:1 geo_unit year using "..\temp\tot_maternal_mortality.dta", ///
        assert(3) keep(3) nogen 
    keep if geo_unit == "Total"
    replace geo_unit = "Brasil" if geo_unit == "Total"
    rename (tot_mortality_w_fertile tot_maternal_mortality) ///
        (mortality_w_fertile maternal_mortality)
    gen mm_ratio = maternal_mortality / mortality_w_fertile

    append using "..\temp\rgds_mm_ratio.dta"
	
	encode geo_unit, gen(geo_unit_num)

    xtset geo_unit_num year

    tssmooth ma ma_mm_ratio  = mm_ratio, window(2 1 2)
    label var   ma_mm_ratio "Maternal mortality over fertile women's mortality"
    
    save "..\temp\brasil_mm_data.dta", replace
end

program import_and_process_uruguay_data
    import excel using "..\..\..\raw\Cuadro 7. Mortalidad Materna 1900-2015.xlsx", clear cellrange(a9:h125) firstrow
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

    save "..\temp\uruguay_mm_data.dta", replace
end

program plot_ratio, 
    syntax, var_ratio(string) start_yr(int) end_yr(int) tline(string)

    twoway (connected `var_ratio' year if inrange(year,`start_yr',`end_yr') & geo_unit == "Brasil", ///
	    yaxis(1) ylabel(0.012(0.01)0.032, axis(1)) mc(navy) lc(navy) lp(dash)) ///
        (connected `var_ratio' year if inrange(year,`start_yr',`end_yr') & geo_unit == "Uruguay", ///
		yaxis(2) ylabel(0.002(0.01)0.022, axis(2)) mc(maroon) lc(maroon) lp(solid)), ///
		tlab(`start_yr'(4)`end_yr') xtitle("Year") ///
        xline(`tline', lcolor(black) lpattern(dot)) ///
		text(0.0325 2003.5 "IS start") ///
		text(0.0325 2011.5 "VTP law") ///
        graphregion(fcolor(white) lcolor(white)) ///
		legend(label(1 "Brazil") label(2 "Uruguay") cols(3)) ///
		l1title("Maternal mortality over fertile women's deaths, Brazil", size(medsmall)) ///
        r1title("Maternal mortality over fertile women's deaths, Uruguay", size(medsmall)) ///
		ytitle("", axis(1)) ytitle("", axis(2))
    graph export ../output/mortality_`var_ratio'.png, replace
end

program did_reg
    syntax, var_ratio(str)
	qui sum `var_ratio' if (geo_unit == "Uruguay" | geo_unit == "Brasil"), meanonly
    local avg_`var_ratio' = r(mean)
	
	reg `var_ratio' post##treatment if ///
	    (geo_unit == "Uruguay" | geo_unit == "Brasil")
		
	file open myfile using "../output/tab_`var_ratio'.txt", write replace
    file write myfile "\begin{threeparttable}" ///
                    _n "\begin{tabular}{l|c} \hline\hline"  ///
                    _n " & Maternal mortality ratio \\ \hline"  ///
                    _n "Mean & " %9.3f (`avg_`var_ratio'') " \\ \hline " ///
                    _n "Coefficient  &  " %9.3f ( _b[1.post#1.treatment]) "  \\ " ///
                    _n "Std. error   & (" %9.3f (_se[1.post#1.treatment]) ") \\ " ///
                    _n "Observations &  " %9.0fc (`e(N)')                 "  \\ " ///
                    _n "\hline\hline" _n "\end{tabular}" 
    file close myfile	
end

main
