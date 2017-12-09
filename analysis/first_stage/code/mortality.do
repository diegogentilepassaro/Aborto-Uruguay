clear all
set more off

program main
	import excel using "..\..\..\raw\Cuadro 7. Mortalidad Materna 1900-2015.xlsx", clear cellrange(a9:h125) firstrow
	rename Año year
	label var year "Year"
	keep if year>=1985
	tsset year
	gen ratio1 = Cifras/Muertesdemujeres

	tssmooth ma ma_muertes = MuertesMaternas, window(3 1 0) //5-year average
	tssmooth ma ma_razon   = Raz, window(3 1 0) //5-year average
	tssmooth ma ma_ratio1 = ratio1, window(3 1 0)
	
	label var ma_ratio1 "Maternal mortality over fertile women's mortality"
	
	plot_ratio, var_ratio(ratio1) start_yr(2000) end_yr(2014) tline(2004)
end

program plot_ratio, 
syntax, var_ratio(string) start_yr(int) end_yr(int) tline(string)
	local var_ratio ma_ratio1
	local start_yr 2000
	local end_yr 2014 
	local tline 2004 2012
	tsline `var_ratio' if inrange(year,`start_yr',`end_yr'), tline(`tline') tlab(2000(4)2014)
	graph export ../output/mortality_`var_ratio'.pdf, replace
end

main
