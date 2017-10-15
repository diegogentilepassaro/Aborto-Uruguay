clear all
set more off

program main_homogeneize_geo_vars 
	homogenize_geo_vars
end

program homogenize_geo_vars
	use ..\base\clean_1998_2016_pers, clear
	
	gen rivera_city = 1 if inrange(anio, 1998, 2005) & loc == "1301"
	replace rivera_city = 1 if anio == 2006 & dpto == 13 & loc == "020"
	
	preserve 
	keep if anio == 2006
	keep anio dpto loc nomloc
	duplicates drop
	replace anio = anio + 1
	rename nomloc nomloc2
	save ../temp/loc_2006, replace
	restore
	
	merge m:1 anio dpto loc using ../temp/loc_2006, nogen

end

main_homogeneize_geo_vars
