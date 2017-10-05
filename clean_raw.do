clear all
set more off
cd "C:\Users\dgentil1\Desktop\aborto_uru_repo\Aborto-Uruguay\raw"
*cd "C:\Users\cravizza\Google Drive\RIIPL\_PIW\abortion_UR\raw"

program main 
	foreach year in 1998 1999 2000 {
	    clean_98_00, year(`year')
	} 
	clean_01_05 
	clean_06 
	clean_07 
	clean_08
	clean_09_16
end

program clean_98_00
    syntax, year(str)
	
	foreach w in 1 2 {
	    foreach c in i m {
			import excel using "`year'\h`year's`w'`c'.xls", clear first
			tempfile temp_h_`w'`c'
			save `temp_h_`w'`c''
		    }
	    append using `temp_h_`w'i'
		tempfile temp_h_`w'
		save `temp_h_`w''
		}

	append using `temp_h_1'
	save ..\base\clean_`year'_h.dta, replace

	foreach w in 1 2 {
	    foreach c in i m {
			import excel using "`year'\p`year's`w'`c'.xls", clear first
			tempfile temp_p_`w'`c'
			save `temp_p_`w'`c''
		    }
	    append using `temp_p_`w'i'
		tempfile temp_p_`w'
		save `temp_p_`w''
		}

	append using `temp_p_1'
	save ..\base\clean_`year'_p.dta, replace
end

program clean_01_05
	* Note: there is no nomdepto for 2005: check running table nomdpto anio
	foreach t in p h {
		foreach year in 2001 2002 2003 2004 2005 {
			import excel using "`year'/`t'`year'.xls", clear first
			capture rename nombre nombarrio
			tempfile temp_`t'_`year'
			save `temp_`t'_`year''
		}
		foreach year in 2001 2002 2003 2004 {
			append using `temp_`t'_`year''
		}
		save ..\base\clean_01_to_05_`t'.dta, replace
	}
end

program clean_06
		usespss FUSIONADO_2006_TERCEROS.sav, clear
		
		capture rename Dpto dpto
		capture rename loc_agr locagr 
		capture rename Trimestre trimestre
		capture rename Estrato estrato
		capture rename PT1 pt1

		keep anio numero nper dpto region_3 region_4 secc segm barrio ///
		    nombarrio trimestre mes estrato pesoano ///
			e26 e27 e30_1 e30_2 e30_3 e30_4 e30_5_2 ///
			e37 e48 f62 f81 f82_1 f82_2 f102 pt1
			
		rename (e26 e27 e30_1 e30_2 e30_3 e30_4 e30_5_2 ///
			e37 e48 f62 f81 f82_1 f82_2 f102 pt1) ///
			(sexo edad afro asia blanco indigena otro estado_civil ///
			estudiante trabajo horas_trabajo meses_trabajando ///
			anios_trabajando busca_trabajo ytotal)
			
		save ..\base\clean_2006, replace	
end

program clean_07
		usespss FUSIONADO_2007_TERCEROS.sav, clear
		
		capture rename Dpto dpto
		capture rename Trimestre trimestre
		capture rename Estrato estrato
		capture rename PT1 pt1

		keep anio numero nper dpto region_3 region_4 secc segm barrio ///
		    nombarrio trimestre mes estrato pesoano ///
			e27 e28 e31_1 e31_2 e31_3 e31_4 e31_5_1 ///
			e40 e50 f68 f88 f89_1 f89_2 f102 pt1
			
		rename (e27 e28 e31_1 e31_2 e31_3 e31_4 e31_5_1 ///
			e40 e50 f68 f88 f89_1 f89_2 f102 pt1) ///
			(sexo edad afro asia blanco indigena otro estado_civil ///
			estudiante trabajo horas_trabajo meses_trabajando ///
			anios_trabajando busca_trabajo ytotal)
			
		save ..\base\clean_2007, replace
end 

program clean_08
		usespss FUSIONADO_2008_TERCEROS.sav, clear
		
		capture rename Dpto dpto
		capture rename Trimestre trimestre
		capture rename Estrato estrato
		capture rename PT1 pt1

		keep anio numero nper dpto region_3 region_4 secc segm barrio ///
		    nombarrio trimestre mes estrato pesoano ///
			e27 e28 e31_1 e31_2 e31_3 e31_4 e31_5_1 ///
			e40 e50 f68 f88_1 f89_1 f89_2 f102 pt1
			
		rename (e27 e28 e31_1 e31_2 e31_3 e31_4 e31_5_1 ///
			e40 e50 f68 f88_1 f89_1 f89_2 f102 pt1) ///
			(sexo edad afro asia blanco indigena otro estado_civil ///
			estudiante trabajo horas_trabajo meses_trabajando ///
			anios_trabajando busca_trabajo ytotal)
			
		save ..\base\clean_2008, replace
end 

program clean_09_16

    forval year=2009/2016 {
	    
		if "`year'" == "2016" {
			usespss HyP_`year'_TERCEROS.sav, clear
			}
			else {
		    usespss FUSIONADO_`year'_TERCEROS.sav, clear
		}
		
		capture rename estratogeo09 estrato
		capture rename estratogeo estrato
        capture rename codbarrio barrio
        capture rename nombrebarr nombarrio
		capture rename estred13 estrato
		capture rename PT1 pt1
		
		capture gen trimestre = 1 if inlist(mes, 1, 2, 3)
		capture replace trimestre = 2 if inlist(mes, 4, 5, 6)
		capture replace trimestre = 3 if inlist(mes, 7, 8, 9)
		capture replace trimestre = 4 if inlist(mes, 10, 11, 12)	

		keep anio numero nper dpto region_3 region_4 secc segm barrio ///
		    nombarrio trimestre mes estrato pesoano ///
			e26 e27 e29_6 e36 e49 f66 f85 f88_1 f88_2 f99 pt1
			
		rename (e26 e27 e29_6 e36 e49 f66 f85 f88_1 f88_2 f99 pt1) ///
			(sexo edad ascendencia estado_civil estudiante trabajo ///
			horas_trabajo meses_trabajando anios_trabajando busca_trabajo ///
			ytotal)
			
		save ..\base\clean_`year', replace
		}
end

main
