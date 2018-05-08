clear all
set more off

program main
	import excel using "..\..\..\raw\Cuadro 7. Mortalidad Materna 1900-2015.xlsx", clear cellrange(a9:h125) firstrow
	rename Año year
	label var year "Year"
	keep if year>=1985
	tsset year
	gen ratio1 = Cifras/Muertesdemujeres

	tssmooth ma ma_muertes = MuertesMaternas, window(2 1 2) //5-year average
	tssmooth ma ma_razon   = Raz, window(2 1 2) //5-year average
	tssmooth ma ma_ratio1  = ratio1, window(2 1 2)
	label var   ma_ratio1 "Maternal mortality over fertile women's mortality"
	
	plot_ratio, var_ratio(ma_ratio1) start_yr(2000) end_yr(2014) tline(2003.5 2011.5)
end

program plot_ratio, 
syntax, var_ratio(string) start_yr(int) end_yr(int) tline(string)
	tsline `var_ratio' if inrange(year,`start_yr',`end_yr') ///
		, recast(connected) mc(blue) lc(blue) tlab(`start_yr'(4)`end_yr') ///
		tline(`tline', lcolor(black) lpattern(dot)) ///
		graphregion(fcolor(white) lcolor(white))
	graph export ../output/mortality_`var_ratio'.pdf, replace
end

main
