clear all
set more off
adopath + ../../library/stata/gslab_misc/ado

program main 
    use ../../base\output\clean_1998_2016, clear

    keep if anio >= 2001
    
    convert_01_05_to_06_11_cod
    convert_07_to_06_11_cod
    fill_missing_loc_var, year(2007) loc_var(nomloc) merge_var(loc)
    fill_missing_loc_var, year(2008) loc_var(loc) merge_var(nomloc)
    save ../temp/2001_2011_loc_homo.dta, replace
    
    homogeneize_loc_to_2012_2014    
    replace ccz = ccz04 if anio == 2012
    drop ccz04 ccz10
    
    tostring dpto, gen(dpto_string)
    replace dpto_string = "0" + dpto_string if  dpto < 10
    gen loc_code = dpto_string + loc
    drop dpto_string
    
    destring loc_code, gen(loc_code_destring)
    drop_rural_areas
    drop loc_code_destring loc
    
    drop if missing(loc_code)
    drop if (missing(anio) | missing(numero) | missing(pers))

    save_data ../temp/clean_loc_2001_2016.dta, key(numero pers anio) replace
end

program convert_01_05_to_06_11_cod
    * Montevideo
    replace loc = "010" if inrange(anio, 2001, 2005) & loc == "0101"

    * Artigas
    replace loc = "020" if inrange(anio, 2001, 2005) & loc == "0201"
    replace loc = "021" if inrange(anio, 2001, 2005) & loc == "0202"
    
    * Canelones
    replace loc = "020" if inrange(anio, 2001, 2005) & loc == "0302"
    replace loc = "021" if inrange(anio, 2001, 2005) & loc == "0301"
    replace loc = "023" if inrange(anio, 2001, 2005) & loc == "0303"    
    replace loc = "024" if inrange(anio, 2001, 2005) & loc == "0304"
    replace loc = "422" if inrange(anio, 2001, 2005) & loc == "0305"
    
    * Cerro Largo
    replace loc = "020" if inrange(anio, 2001, 2005) & loc == "0401"
    replace loc = "522" if inrange(anio, 2001, 2005) & loc == "0402"

    * Colonia
    replace loc = "320" if inrange(anio, 2001, 2005) & loc == "0501"
    replace loc = "321" if inrange(anio, 2001, 2005) & loc == "0502"
    replace loc = "021" if inrange(anio, 2001, 2005) & loc == "0503"    
    replace loc = "022" if inrange(anio, 2001, 2005) & loc == "0504"
    replace loc = "023" if inrange(anio, 2001, 2005) & loc == "0505"

    * Durazno
    replace loc = "020" if inrange(anio, 2001, 2005) & loc == "0601"
    replace loc = "421" if inrange(anio, 2001, 2005) & loc == "0602"

    * Flores
    replace loc = "320" if inrange(anio, 2001, 2005) & loc == "0701"

    * Florida
    replace loc = "220" if inrange(anio, 2001, 2005) & loc == "0801"
    replace loc = "421" if inrange(anio, 2001, 2005) & loc == "0802"

    * Lavalleja
    replace loc = "020" if inrange(anio, 2001, 2005) & loc == "0901"
    replace loc = "522" if inrange(anio, 2001, 2005) & loc == "0902"

    * Maldonado
    replace loc = "020" if inrange(anio, 2001, 2005) & loc == "1001"
    replace loc = "021" if inrange(anio, 2001, 2005) & loc == "1002"
    replace loc = "022" if inrange(anio, 2001, 2005) & loc == "1003"    
    replace loc = "023" if inrange(anio, 2001, 2005) & loc == "1004"
    replace loc = "024" if inrange(anio, 2001, 2005) & loc == "1005"

    * Paysandu
    replace loc = "020" if inrange(anio, 2001, 2005) & loc == "1101"
    replace loc = "521" if inrange(anio, 2001, 2005) & loc == "1102"

    * Rio Negro
    replace loc = "020" if inrange(anio, 2001, 2005) & loc == "1201"
    replace loc = "421" if inrange(anio, 2001, 2005) & loc == "1202"
    
    *Rivera
    replace loc = "020" if inrange(anio, 2001, 2005) & loc == "1301"
    replace loc = "522" if inrange(anio, 2001, 2005) & loc == "1302"
    
    *Rocha
    replace loc = "320" if inrange(anio, 2001, 2005) & loc == "1401"
    replace loc = "422" if inrange(anio, 2001, 2005) & loc == "1403"
    replace loc = "521" if inrange(anio, 2001, 2005) & loc == "1404"
    
    * Salto
    replace loc = "020" if inrange(anio, 2001, 2005) & loc == "1501"

    *San Jose
    replace loc = "021" if inrange(anio, 2001, 2005) & loc == "1601"
    replace loc = "020" if inrange(anio, 2001, 2005) & loc == "1602"
    replace loc = "022" if inrange(anio, 2001, 2005) & loc == "1603"

    *Soriano
    replace loc = "220" if inrange(anio, 2001, 2005) & loc == "1701"
    replace loc = "021" if inrange(anio, 2001, 2005) & loc == "1702"

    *Tacuarembo
    replace loc = "020" if inrange(anio, 2001, 2005) & loc == "1801"
    replace loc = "321" if inrange(anio, 2001, 2005) & loc == "1802"

    *Treinta y Tres
    replace loc = "020" if inrange(anio, 2001, 2005) & loc == "1901"
end

program convert_07_to_06_11_cod    
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
end

program fill_missing_loc_var
    syntax, year(int) loc_var(str) merge_var(str)
    
    preserve 
        keep if anio == 2006
        keep anio dpto `loc_var' `merge_var'
        duplicates drop anio dpto loc, force
        replace anio = `year'
        rename `loc_var' `loc_var'2
        save ../temp/loc_2006, replace
    restore    

    merge m:1 anio dpto `merge_var' using ../temp/loc_2006, ///
        keepusing(`loc_var'2) nogen
    
    replace `loc_var' = `loc_var'2 if anio == `year'
    drop `loc_var'2
end

program homogeneize_loc_to_2012_2014
    use ../temp/2001_2011_loc_homo.dta, clear
    
    merge m:1 dpto loc using ../../base/output/loc_xwalk.dta, ///
        keepusing(loc12_14)
    replace loc12_14 = loc if inrange(anio, 2012,2014) 
    drop if missing(loc)    
        
    replace loc = loc12_14
    drop _merge loc12_14
end

program drop_rural_areas
    * Artigas
    drop if dpto == 2 & loc_code_destring == 0231900

     * Canelones
    drop if dpto == 3 & loc_code_destring == 0303900
    
    * Cerro Largo
    drop if dpto == 4 & loc_code_destring == 0431900

    * Colonia
    drop if dpto == 5 & loc_code_destring == 0532900

    * Durazno
    drop if dpto == 6 & loc_code_destring == 0633900

    * Flores
    drop if dpto == 7 & loc_code_destring == 0734900

    * Florida
    drop if dpto == 8 & loc_code_destring == 0834900

    * Lavalleja
    drop if dpto == 9 & loc_code_destring == 0934900

    * Maldonado
    drop if dpto == 10 & loc_code_destring == 1035900

    * Paysandu
    drop if dpto == 11 & loc_code_destring == 1136900

    * Rio Negro
    drop if dpto == 12 & loc_code_destring == 1236900
    
    *Rivera
    drop if dpto == 13 & loc_code_destring == 1331900
    
    *Rocha
    drop if dpto == 14 & loc_code_destring == 1435900
    
    * Salto
    drop if dpto == 15 & loc_code_destring == 1536900

    *San Jose
    drop if dpto == 16 & loc_code_destring == 1632900

    *Soriano
    drop if dpto == 17 & loc_code_destring == 1732900

    *Tacuarembo
    drop if dpto == 18 & loc_code_destring == 1833900

    *Treinta y Tres
    drop if dpto == 19 & loc_code_destring == 1931900
end

* EXECUTE
main
