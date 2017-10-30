clear all
set more off

program main_homogeneize_geo_vars 
	use ..\base\clean_1998_2016, clear
	
	fix_98_05
	fix_2007
	fix_2008
	save ../temp/98_2011_loc_homo.dta, replace
	
	import excel lista_homogen_codes_geo.xlsx, sheet("Sheet1") ///
	    cellrange(B1:F100) firstrow clear
	rename (codigodpto localidad codigo98_2005 codigo_2006_2011 codigo_2012_2014) ///
	    (dpto nomloc2 loc98_05 loc loc12_14)
    save ../temp/loc_xwalk.dta, replace
	
    homogeneize_loc_to_2012_2014
		
	drop if missing(anio)
	
	replace ccz = ccz04 if anio == 2012
	drop ccz04 ccz10
	
	tostring dpto, gen(dpto_string)
	gen loc_code = dpto_string + loc
	drop dpto_string
	destring loc_code, replace
	
	*replace loc_code = ccz if dpto == 1
	
	save ..\temp\clean_loc_1998_2016.dta, replace
end

program fix_98_05
    * Montevideo
	replace loc = "010" if inrange(anio, 1998, 2005) & loc == "0101"

	* Artigas
	replace loc = "020" if inrange(anio, 1998, 2005) & loc == "0201"
	replace loc = "021" if inrange(anio, 1998, 2005) & loc == "0202"
	
	* Canelones
	replace loc = "020" if inrange(anio, 1998, 2005) & loc == "0302"
	replace loc = "021" if inrange(anio, 1998, 2005) & loc == "0301"
	replace loc = "023" if inrange(anio, 1998, 2005) & loc == "0303"	
	replace loc = "024" if inrange(anio, 1998, 2005) & loc == "0304"
	replace loc = "422" if inrange(anio, 1998, 2005) & loc == "0305"
	
	* Cerro Largo
	replace loc = "020" if inrange(anio, 1998, 2005) & loc == "0401"
	replace loc = "522" if inrange(anio, 1998, 2005) & loc == "0402"

    * Colonia
	replace loc = "320" if inrange(anio, 1998, 2005) & loc == "0501"
	replace loc = "321" if inrange(anio, 1998, 2005) & loc == "0502"
	replace loc = "021" if inrange(anio, 1998, 2005) & loc == "0503"	
	replace loc = "022" if inrange(anio, 1998, 2005) & loc == "0504"
	replace loc = "023" if inrange(anio, 1998, 2005) & loc == "0505"

	* Durazno
	replace loc = "020" if inrange(anio, 1998, 2005) & loc == "0601"
	replace loc = "421" if inrange(anio, 1998, 2005) & loc == "0602"

	* Flores
	replace loc = "320" if inrange(anio, 1998, 2005) & loc == "0701"

	* Florida
	replace loc = "220" if inrange(anio, 1998, 2005) & loc == "0801"
	replace loc = "421" if inrange(anio, 1998, 2005) & loc == "0802"

	* Lavalleja
	replace loc = "020" if inrange(anio, 1998, 2005) & loc == "0901"
	replace loc = "522" if inrange(anio, 1998, 2005) & loc == "0902"

    * Maldonado
	replace loc = "020" if inrange(anio, 1998, 2005) & loc == "1001"
	replace loc = "021" if inrange(anio, 1998, 2005) & loc == "1002"
	replace loc = "022" if inrange(anio, 1998, 2005) & loc == "1003"	
	replace loc = "023" if inrange(anio, 1998, 2005) & loc == "1004"
	replace loc = "024" if inrange(anio, 1998, 2005) & loc == "1005"

	* Paysandu
	replace loc = "020" if inrange(anio, 1998, 2005) & loc == "1101"
	replace loc = "521" if inrange(anio, 1998, 2005) & loc == "1102"

	* Rio Negro
	replace loc = "020" if inrange(anio, 1998, 2005) & loc == "1201"
	replace loc = "421" if inrange(anio, 1998, 2005) & loc == "1202"
	
    *Rivera
	replace loc = "020" if inrange(anio, 1998, 2005) & loc == "1301"
	replace loc = "522" if inrange(anio, 1998, 2005) & loc == "1302"
	
    *Rocha
	replace loc = "320" if inrange(anio, 1998, 2005) & loc == "1401"
	replace loc = "422" if inrange(anio, 1998, 2005) & loc == "1403"
	replace loc = "521" if inrange(anio, 1998, 2005) & loc == "1404"
	
	* Salto
	replace loc = "020" if inrange(anio, 1998, 2005) & loc == "1501"

    *San Jose
	replace loc = "021" if inrange(anio, 1998, 2005) & loc == "1601"
	replace loc = "020" if inrange(anio, 1998, 2005) & loc == "1602"
	replace loc = "022" if inrange(anio, 1998, 2005) & loc == "1603"

    *Soriano
	replace loc = "220" if inrange(anio, 1998, 2005) & loc == "1701"
	replace loc = "021" if inrange(anio, 1998, 2005) & loc == "1702"

    *Tacuarembo
	replace loc = "020" if inrange(anio, 1998, 2005) & loc == "1801"
	replace loc = "321" if inrange(anio, 1998, 2005) & loc == "1802"

    *Treinta y Tres
	replace loc = "020" if inrange(anio, 1998, 2005) & loc == "1901"
end

program fix_2007	
    replace loc = substr(loc, 3, 3) if anio == 2007
	
	* Montevideo
	replace loc = "010" if anio == 2007 & loc == "020" & dpto == 1

	* Artigas
	replace loc = "020" if anio == 2007 & loc == "220" & dpto == 2
	replace loc = "021" if anio == 2007 & loc == "621" & dpto == 2
	replace loc = "000" if anio == 2007 & loc == "521" & dpto == 2

	* Canelones
	replace loc = "020" if anio == 2007 & loc == "121" & dpto == 3
	replace loc = "022" if anio == 2007 & loc == "222" & dpto == 3
	replace loc = "023" if anio == 2007 & loc == "323" & dpto == 3
	replace loc = "000" if anio == 2007 & loc == "528" & dpto == 3
	
	* Cerro Largo
	replace loc = "020" if anio == 2007 & loc == "220" & dpto == 4
	replace loc = "000" if anio == 2007 & loc == "521" & dpto == 4

    * Colonia
	replace loc = "021" if anio == 2007 & loc == "421" & dpto == 5
	replace loc = "023" if anio == 2007 & loc == "323" & dpto == 5
	replace loc = "000" if anio == 2007 & loc == "521" & dpto == 5
	
	* Durazno
	replace loc = "020" if anio == 2007 & loc == "220" & dpto == 6
	replace loc = "000" if anio == 2007 & loc == "721" & dpto == 6

	* Flores
	replace loc = "000" if anio == 2007 & loc == "721" & dpto == 7

	* Florida
	replace loc = "000" if anio == 2007 & loc == "622" & dpto == 8

	* Lavalleja
	replace loc = "020" if anio == 2007 & loc == "220" & dpto == 9
	replace loc = "000" if anio == 2007 & loc == "521" & dpto == 9

    * Maldonado
	replace loc = "020" if anio == 2007 & loc == "320" & dpto == 10
	replace loc = "021" if anio == 2007 & loc == "321" & dpto == 10
	replace loc = "023" if anio == 2007 & loc == "523" & dpto == 10
	replace loc = "024" if anio == 2007 & loc == "524" & dpto == 10
	replace loc = "000" if anio == 2007 & loc == "521" & dpto == 10

	* Paysandu
	replace loc = "020" if anio == 2007 & loc == "120" & dpto == 11
	replace loc = "021" if anio == 2007 & loc == "822" & dpto == 11
	replace loc = "000" if anio == 2007 & loc == "621" & dpto == 11
	
	* Rio Negro
	replace loc = "020" if anio == 2007 & loc == "320" & dpto == 12
	replace loc = "000" if anio == 2007 & loc == "621" & dpto == 12
	
    *Rivera
	replace loc = "020" if anio == 2007 & loc == "220" & dpto == 13
	replace loc = "000" if anio == 2007 & loc == "521" & dpto == 13
	
    *Rocha
	replace loc = "000" if anio == 2007 & loc == "722" & dpto == 14
	
	* Salto
	replace loc = "020" if anio == 2007 & loc == "120" & dpto == 15
	replace loc = "000" if anio == 2007 & loc == "522" & dpto == 15

    *San Jose
	replace loc = "020" if anio == 2007 & loc == "220" & dpto == 16
	replace loc = "021" if anio == 2007 & loc == "321" & dpto == 16
	replace loc = "022" if anio == 2007 & loc == "421" & dpto == 16
	replace loc = "000" if anio == 2007 & loc == "621" & dpto == 16

    *Soriano
	replace loc = "021" if anio == 2007 & loc == "321" & dpto == 17
	replace loc = "091" if anio == 2007 & loc == "521" & dpto == 17
	replace loc = "000" if anio == 2007 & loc == "622" & dpto == 17

    *Tacuarembo
	replace loc = "020" if anio == 2007 & loc == "220" & dpto == 18
	replace loc = "000" if anio == 2007 & loc == "521" & dpto == 18
	
    *Treinta y Tres
	replace loc = "020" if anio == 2007 & loc == "220" & dpto == 19
	replace loc = "000" if anio == 2007 & loc == "790" & dpto == 19
	
	fill_missing_loc, dest_year(2007) ren_var(nomloc)
	
	merge m:1 anio dpto loc using ../temp/loc_2006.dta, nogen
	
	replace nomloc = nomloc2 if anio == 2007
	drop nomloc2
end

program fix_2008
	fill_missing_loc, dest_year(2008) ren_var(loc)
	
	merge m:1 anio dpto nomloc using ../temp/loc_2006, nogen
	
	replace loc = loc2 if anio == 2008
	drop loc2
end

program fill_missing_loc
    syntax, dest_year(str) ren_var(str)
    
	preserve 
	keep if anio == 2006
	keep anio dpto loc nomloc
	duplicates drop anio dpto loc, force
	replace anio = `dest_year'
	rename `ren_var' `ren_var'2
	save ../temp/loc_2006, replace
	restore
end

program homogeneize_loc_to_2012_2014
	use ../temp/98_2011_loc_homo.dta, clear
	
	merge m:1 dpto loc using ../temp/loc_xwalk.dta
	
	replace loc = "000" if missing(loc)
	
	replace loc = loc12_14 if _merge == 3
	replace nomloc = nomloc2
	
	drop _merge nomloc2 loc12_14 loc98_05
	
	replace loc = "000" if length(loc) < 5
    
    merge m:1 dpto loc using ../temp/loc_xwalk.dta
    
	replace loc = loc12_14 if _merge == 3
	replace nomloc = nomloc2
	
	drop _merge nomloc2 loc12_14 loc98_05

	save ..\temp\clean_98_2016_temp.dta, replace
end

main_homogeneize_geo_vars
