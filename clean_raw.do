clear all
set more off
*cd "C:\Users\dgentil1\Desktop\aborto_uru_repo\Aborto-Uruguay\raw"
cd "C:\Users\cravizza\Google Drive\Projects\proyecto_aborto\raw"

program main 
	append_different_waves_98_00
	clean_98_00
	clean_01_05 
	clean_06 
	clean_07 
	clean_08
	clean_09_16
end

program append_different_waves_98_00
   	
	foreach year in 1998 1999 2000 {
		foreach t in p h {
			foreach w in 1 2 {
				foreach c in i m {
					import excel using "`year'/`t'`year's`w'`c'.xls", clear first
					tempfile temp_`t'_`w'`c'
					save `temp_`t'_`w'`c''
					}
				append using `temp_`t'_`w'i'
				tempfile temp_`t'_`w'
				save `temp_`t'_`w''
				}
			append using `temp_`t'_1'
			save ..\base\preclean_`year'_`t'.dta, replace
		}
	}
	
end

program clean_98_00
	* Note: can't find: afro asia blanco indigena otro then generated raza equal missing
	forvalues year=1998/2000 {
		use ..\base\preclean_`year'_p.dta, replace
		keep    correlativ persona pe1  pe1a pe1b pe1c pe1d    pe1e pe1h  peso* ccz ///
				pe2 pe3 pe5  pobpcoac pe6 pf133 pe14* pf053 pf37 pf38 pf351 pt1
		
		rename (correlativ persona pe1  pe1a pe1b pe1c pe1d    pe1e pe1h    ) ///
			   (numero     pers    nper anio semn dpto seccion segm estrato )

			   
		rename (pe2  pe5           pobpcoac         pf133         pe141 pe142 ///
				pe3  pf053         pf38             pf37             pf351         pt1)  ///
			   (sexo estado_civil  codigo_actividad  estudiante    educ  ult_anio_educ ///
				edad horas_trabajo meses_trabajando anios_trabajando busca_trabajo ytotal)
				
		gen married = (estado_civil==1|estado_civil==2)
		gen etnia = .
		save ..\base\clean_`year'_p.dta, replace
		}
				
end

program clean_01_05
	* Note: there is no nomdepto for 2005: check running table nomdpto anio
	* Can't find: meses_trabajando anios_trabajando
	foreach t in p h {
		foreach year in 2001 2002 2003 2004 2005 {
			import excel using "`year'/`t'`year'.xls", clear first
			capture rename nombre nombarrio
			save ..\base\clean_`year'_`t'.dta, replace
		}
	}
	foreach year in 2001 2002 2003 2004 2005 {
		use ..\base\clean_`year'_p.dta, clear
		keep anio correlativ nper dpto  secc segm barrio ccz  nombarrio e11* e13 ///
		 mes estrato pesoan  e1 e2 e4 ///
		 e9 f1_1 f17_1 f23 pt1
			 
		capture     gen trimestre = 1 if inlist(mes, 1, 2, 3)
		capture replace trimestre = 2 if inlist(mes, 4, 5, 6)
		capture replace trimestre = 3 if inlist(mes, 7, 8, 9)
		capture replace trimestre = 4 if inlist(mes, 10, 11, 12)
		
		rename (correlativ pesoan  e1   e2   e4 ///
				e9         f1_1    f17_1         f23           pt1) ///
			   (numero     pesoano sexo edad estado_civil ///
				estudiante trabajo horas_trabajo busca_trabajo ytotal)

		gen meses_trabajando = .
		gen anios_trabajando = .
		gen married = (estado_civil==1|estado_civil==2)
		gen etnia = .
		save ..\base\clean_`year'_p.dta, replace
	}
	* Estudiante: {1=si,2=no} --> but estudiante=0 en 3.5%, would it be no response?
end

program clean_etnia_variable
	* Reorganize etnia variables
		foreach var in asia afro blanco indigena otro {
			replace `var'=0 if `var'!=1
			assert  `var'==1 | `var'==0
			gen _`var' = `var'
		}
		* Create mestizo if blanco and either afro or indigena or both
		capture gen mestizo = 0
		gen num_race0 = asia+afro+blanco+indigena+otro+mestizo
		local cond_mestizo "(num_race==2 & _blanco==1 & (_afro==1 | _indigena==1))|(num_race==3 & _blanco==1 & _afro==1 & _indigena==1)"
		replace mestizo  = 1 if `cond_mestizo'
		replace afro     = 0 if `cond_mestizo'
		replace indigena = 0 if `cond_mestizo'
		replace blanco   = 0 if `cond_mestizo'
		* If blanco and otro, then blanco only
		replace otro     = 0 if num_race0==2 & _blanco==1 & _otro==1 
		* Set to otro if more than one (updated) race
		gen num_race1    = asia+afro+blanco+indigena+otro+mestizo
		replace otro     = 1 if num_race1 > 1 | num_race1==0
		foreach var in indigena afro asia blanco mestizo {
			replace `var' = 0 if num_race1 > 1
		}
		assert asia+afro+blanco+indigena+otro+mestizo==1
		drop num_race* _*
		* Gen etnia 
		gen etnia = .
		local i=0
		foreach var in otro afro asia blanco indigena mestizo {
			replace etnia = 1 if `var'==1
			local i=`i'+1
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
		
		gen     married  = (estado_civil==2)	
		* Create mestizo dummy from otro
		gen     mestizo  = regexm(otro,"[Mm][Ee][Ss][Tt][Ii][Zz]*")
		replace asia     = 1   if regexm(otro,"[Aa][Ss][Ii][Aa]*")==1
		replace blanco   = 1   if regexm(otro,"[Bb][Ll][Aa][Nn][Cc]*")==1
		replace otro     = ""  if regexm(otro,"[Bb][Ll][Aa][Nn][Cc]*")==1 ///
								| regexm(otro,"[Aa][Ss][Ii][Aa]*")==1 ///
								| regexm(otro,"[Mm][Ee][Ss][Tt][Ii][Zz]*")==1
		gen     otro_new = !mi(otro)
		drop    otro
		rename  otro_new otro
		replace otro     = 1 if (asia!=1 & afro!=1 & blanco!=1 & indigena!=1 & otro!=1 & mestizo!=1)
		clean_etnia_variable
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
		
		gen married = (estado_civil==2)
		clean_etnia_variable
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

		gen married = (estado_civil==2)		
		clean_etnia_variable
		save ..\base\clean_2008, replace
end 

program clean_09_16

    forval year=2009/2016 {
	    local year 2009
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
		
		gen married = (estado_civil==3)	
		gen etnia = ascendencia
		replace etnia=0 if ascendencia==5
		save ..\base\clean_`year', replace
		}
end

main
