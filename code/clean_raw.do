clear all
set more off

program main_clean_raw
	*append_different_waves_98_00 
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
					import excel using "..\raw/`year'/`t'`year's`w'`c'.xls", clear first
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
		 use ..\base\preclean_`year'_p.dta, clear

         rename correlativ ident
         merge m:1 ident using ..\base\preclean_`year'_h.dta, nogen
		 save ..\base\preclean_`year'.dta, replace
	}
	
end

program clean_98_00
	* Note: can't find: afro asia blanco indigena otro then generated raza equal missing
	forvalues year=1998/2000 {
		use ..\base\preclean_`year'.dta, replace		
		
		gen     primaria   = (pe141==8|pe141==1|pe141==2|pe141==3|pe141==4)
		gen     secundaria = (((pe141==3|pe141==4) & pe15==1)|pe141==5|pe141==6|pe141==7)
		gen     terciaria  = ((pe141==5|pe141==6|pe141==7) & pe15==1)
		gen     educ_level = 1              if primaria==1
		replace educ_level = 2              if secundaria==1
		replace educ_level = 3              if terciaria==1
		assert  pe141==0 | pe141==9         if educ_level==.
		replace educ_level = 1              if educ_level==.
		
		gen estudiante = (pobpcoac==33)

		gen	c98_resid_house		=	(hc1==1)
		gen	c98_resid_owned		=	(hd3==1|hd3==2)
		gen	c98_nbr_rooms		=	hd41
		gen	c98_nbr_bedrooms	=	hd42
		gen	c98_b_piped_water	=	(hd6==1)
		gen	c98_hhld_toilet		=	(hd7==1)
		gen	c98_b_sewage		=	(hd9==1)
		gen	c98_hhld_stove		=	(hd102!=7)
		gen	c98_hhld_hot_water	=	(hd111==1)
		gen	c98_hhld_refrigerat	=	(hd112==1|hd113==1)
		gen	c98_hhld_tv			=	(hd114==1|hd115==1)
		gen	c98_hhld_vcr		=	(hd116==1)
		gen	c98_hhld_wash_mac	=	(hd117==1)
		gen	c98_hhld_dishwasher	=	(hd118==1)
		gen	c98_hhld_microwave	=	(hd119==1)
		gen	c98_hhld_car		=	(hd1110==1)
				
		keep    c98_* educ_level estudiante ident persona pe1  pe1a pe1b pe1c pe1d    pe1e pe1h  peso* ccz ///
				pe2 pe3 pe5  pobpcoac pf133 pf053 pf37 pf38 pf351 pt1 ///
				locech nomlocech ht11 hd21 hd22
		
		rename (ident persona pe1  pe1a pe1b pe1c pe1d    pe1e pe1h locech nomlocech ///
		        ht11 hd21 hd22) ///
			   (numero     pers    nper anio semana dpto secc segm estrato loc nomloc ///
			    y_hogar cantidad_personas cantidad_mayores)

		rename (pe2  pe5           pobpcoac               ///
				pe3  pf053         pf38             pf37             pf351         pt1)  ///
			   (hombre estado_civil  codigo_actividad    ///
				edad horas_trabajo meses_trabajando anios_trabajando busca_trabajo ytotal)
	    
		gen trimestre = 1 if inrange(semana, 1, 12)
		replace trimestre = 2 if inrange(semana, 13, 24)
		replace trimestre = 3 if inrange(semana, 25, 36)
		replace trimestre = 4 if inrange(semana, 37, 48)
		
		gen trabajo = (codigo_actividad == 11 | codigo_actividad == 12)
		drop codigo_actividad
		gen married = (estado_civil==1|estado_civil==2)
		gen etnia = .
		assert nper==pers
		drop nper
		save ..\base\clean_`year'.dta, replace
		}
end

program clean_01_05
	* Note: there is no nomdepto for 2005: check running table nomdpto anio
	* Can't find: meses_trabajando anios_trabajando
	
	foreach year in 2001 2002 2003 2004 2005 {
		foreach t in p h {
			import excel using "..\raw/`year'/`t'`year'.xls", clear first
			save ..\base\preclean_`year'_`t'.dta, replace
		}
		use ..\base\preclean_`year'_p.dta, clear

        merge m:1 correlativ using ..\base\preclean_`year'_h.dta, nogen
	    save ..\base\preclean_`year'.dta, replace
	}
	foreach year in 2001 2002 2003 2004 2005 {
		use ..\base\preclean_`year'.dta, clear
		
		gen     primaria   = e11_1 + e11_2
		gen     secundaria = max(e11_3,e11_4)
		gen     terciaria  = max(e11_5,e11_6)
		gen     educ_level = 1 if primaria>=0
		replace educ_level = 2 if secundaria==6 | (e11_3+e11_4==6 & e13==1) 
		replace educ_level = 3 if terciaria>0 & e13==1
		assert !mi(educ_level)

		gen estudiante = (pobpcoac == 7)

		gen	c98_resid_house		=	(c1==1)
		gen	c98_resid_owned		=	(d2==1|d2==2)
		gen	c98_nbr_rooms		=	d3
		gen	c98_nbr_bedrooms	=	d4
		gen	c98_b_piped_water	=	(d6==1)
		gen	c98_hhld_toilet		=	(d7==1)
		gen	c98_b_sewage		=	(d8==1)
		gen	c98_hhld_stove		=	(d9!=5)
		gen	c98_hhld_hot_water	=	(d10_1==1|d10_2==1)
		gen	c98_hhld_refrigerat	=	(d10_3==1)
		gen	c98_hhld_tv			=	(d10_4==1)
		gen	c98_hhld_vcr		=	(d10_6==1)
		gen	c98_hhld_wash_mac	=	(d10_7==1)
		gen	c98_hhld_dishwasher	=	(d10_8==1)
		gen	c98_hhld_microwave	=	(d10_9==1)
		gen	c98_hhld_car		=	(d10_12==1)
		gen	c01_hhld_computer	=	(d10_10==1)
		gen	c01_hhld_internet	=	(d10_11==1)
		gen	c01_hhld_phone		=	(d10_13==1)
		gen	c01_hhld_cable_tv	=	(d10_5==1)
		
		keep  c98_*  c01_* estudiante educ_level anio correlativ nper dpto  secc segm ccz  /*e11 e13*/ ///
		    mes estrato pesoan pesosem pesotri e1 e2 e4 e9 f1_1 f17_1 f23 pt1 ///
		    locech nomlocech ht11 d14 d16
			 
		capture gen trimestre = 1 if inlist(mes, 1, 2, 3)
		capture replace trimestre = 2 if inlist(mes, 4, 5, 6)
		capture replace trimestre = 3 if inlist(mes, 7, 8, 9)
		capture replace trimestre = 4 if inlist(mes, 10, 11, 12)
		
		rename (nper correlativ e1   e2   e4 ///
				f1_1    f17_1         f23           pt1 locech nomlocech ///
				ht11 d14 d16) ///
			   (pers numero hombre edad estado_civil ///
				trabajo horas_trabajo busca_trabajo ytotal loc nomloc ///
				y_hogar cantidad_mayores cantidad_personas)

		gen meses_trabajando = .
		gen anios_trabajando = .
		gen married = (estado_civil==1|estado_civil==2)
		gen etnia = .
		save ..\base\clean_`year'.dta, replace
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
		usespss ../raw/FUSIONADO_2006_TERCEROS.sav, clear
		
		capture rename Dpto dpto
		capture rename Trimestre trimestre
		capture rename Estrato estrato
		capture rename PT1 pt1
		capture rename HT11 ht11
		
		gen     primaria   = (e48==1 & (e50_1>0|e50_2>0|e50_3>0|e50_4>0|e50_5>0|e50_6>0|e50_7>0|e50_8>0)) ///
						   | (e48==2 & (e52_1_1>0|e52_2_1>0|e52_3_1>0|e52_3_3==1|e52_3_3==2|e52_3_3==3))
		gen     secundaria = (e48==1 & (e50_9>0|e50_10>0|e50_11>0|e50_12>0)) ///
						   | (e48==2 & (e52_2_2==1|e52_3_2==1|e52_3_3==1|e52_4_1>0|e52_5_1>0|e52_6_1>0|e52_7_1>0))
		gen     terciaria  = (e48==1 & (e50_12>0)) ///
						   | (e48==2 & (e52_4_2==1|e52_5_2==1|e52_6_2==1|e52_7_2==1))
		gen     educ_level = 1 if primaria==1
		replace educ_level = 2 if secundaria==1
		replace educ_level = 3 if terciaria==1
		assert e51==2 if educ_level ==. & e51!=0
		replace educ_level=1 if educ_level==.

		gen estudiante = (Pobpcoac == 7)

		gen	c98_resid_house		=	(c1!=5)
		gen	c06_mat_walls		=	(c2==1|c2==2)
		gen	c06_mat_roof		=	(c3==1|c3==2)
		gen	c06_mat_floor		=	(c4==1|c4==2)
		gen	c98_resid_owned		=	(d7_1==1|d7_1==2|d7_1==3|d7_1==4)
		gen	c98_nbr_rooms		=	d8
		gen	c98_nbr_bedrooms	=	d9
		gen	c98_b_piped_water	=	(d13==1)
		gen	c98_hhld_toilet		=	(d14==1)
		gen	c98_b_sewage		=	(d17==1)
		gen	c06_b_electr		=	(d18_1==1|d18_1==2)
		gen	c98_hhld_stove		=	(d19!=3)
		gen	c98_hhld_hot_water	=	(d21_1_1==1|d21_1_2==1|d21_1_3==1|d21_2_1==1|d21_2_2==1)
		gen	c98_hhld_refrigerat	=	(d21_3==1|d21_4==1)
		gen	c98_hhld_TV			=	(d21_5_1==1)
		gen	c98_hhld_VCR		=	(d21_8==1|d21_9==1)
		gen	c98_hhld_wash_mac	=	(d21_10==1)
		gen	c98_hhld_dishwasher	=	(d21_12==1)
		gen	c98_hhld_microwave	=	(d21_13==1)
		gen	c98_hhld_car		=	(d21_18_1==1)
		gen	c01_hhld_computer	=	(d21_14_1==1)
		gen	c01_hhld_internet	=	(d21_15==1)
		gen	c01_hhld_phone		=	(d21_16_1==1|d21_17_1==1)
		gen	c01_hhld_cable_TV	=	(d21_7==1)

		keep  c98_*  c01_* c06_* estudiante anio numero nper dpto region_3 region_4 secc segm ccz ///
		    trimestre mes estrato pesoano pesosem pesotri ///
			e26 e27 e30_1 e30_2 e30_3 e30_4 e30_5_2 ///
			e37 e48 f62 f81 f82_1 f82_2 f102 pt1 locagr ///
			nom_locagr educ_level ht11 d25 d23 lp_06 li_06
			
		rename (nper e26 e27 e30_1 e30_2 e30_3 e30_4 e30_5_2 ///
			e37 f62 f81 f82_1 f82_2 f102 pt1 locagr nom_locagr  pesoano ///
			ht11 d23 d25) ///
			(pers hombre edad afro asia blanco indigena otro estado_civil ///
			 trabajo horas_trabajo meses_trabajando ///
			anios_trabajando busca_trabajo ytotal loc nomloc pesoan ///
			y_hogar cantidad_mayores cantidad_personas)
		
		destring anio, replace
		destring secc, replace
		destring segm, replace
		destring estrato, replace

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
		usespss ../raw/FUSIONADO_2007_TERCEROS.sav, clear
		
		capture rename Dpto dpto
		capture rename Trimestre trimestre
		capture rename Estrato estrato
		capture rename PT1 pt1
		capture rename HT11 ht11
		
		gen     primaria   = (e50==1 & (e52_1>0|e52_2>0|e52_3>0|e52_4>0|e52_5>0|e52_6>0|e52_7>0|e52_8>0)) ///
						   | (e50==2 & (e54_1_1>0|e54_2_1>0|e54_3_1>0|e54_3_3==1|e54_3_3==2|e54_3_3==3))
		gen     secundaria = (e50==1 & (e52_9>0|e52_10>0|e52_11>0|e52_12>0)) ///
						   | (e50==2 & (e54_2_2==1|e54_3_2==1|e54_3_3==1|e54_4_1>0|e54_5_1>0|e54_6_1>0|e54_7_1>0))
		gen     terciaria  = (e50==1 & (e52_12>0)) ///
						   | (e50==2 & (e54_4_2==1|e54_5_2==1|e54_6_2==1|e54_7_2==1))	
		gen     educ_level = 1 if primaria==1
		replace educ_level = 2 if secundaria==1
		replace educ_level = 3 if terciaria==1
		assert e53==2 if educ_level ==. & e53!=0
		replace educ_level=1 if educ_level==.
		
		gen estudiante = (Pobpcoac == 7)

		gen	c98_resid_house		=	(c1!=5)
		gen	c06_mat_walls		=	(c2==1|c2==2)
		gen	c06_mat_roof		=	(c3==1|c3==2)
		gen	c06_mat_floor		=	(c4==1|c4==2)
		gen	c98_resid_owned		=	(d8_1==1|d8_1==2|d8_1==3|d8_1==4)
		gen	c98_nbr_rooms		=	d9
		gen	c98_nbr_bedrooms	=	d10
		gen	c98_b_piped_water	=	(d14_1==1)
		gen	c98_hhld_toilet		=	(d15==1)
		gen	c98_b_sewage		=	(d18_1==1)
		gen	c06_b_electr		=	(d19_1==1|d19_1==2)
		gen	c98_hhld_stove		=	(d20!=3)
		gen	c98_hhld_hot_water	=	(d22_1_1==1|d22_1_2==1|d22_1_3==1|d22_2_1==1|d22_2_2==1)
		gen	c98_hhld_refrigerat	=	(d22_1_2==1|d22_4==1)
		gen	c98_hhld_TV			=	(d22_5_1==1)
		gen	c98_hhld_VCR		=	(d22_8==1|d22_9==1)
		gen	c98_hhld_wash_mac	=	(d22_10==1)
		gen	c98_hhld_dishwasher	=	(d22_12==1)
		gen	c98_hhld_microwave	=	(d22_13==1)
		gen	c98_hhld_car		=	(d22_18_1==1)
		gen	c01_hhld_computer	=	(d22_14_1==1)
		gen	c01_hhld_internet	=	(d22_15_1==1|d22_15_2==1)
		gen	c01_hhld_phone		=	(d22_16_1==1|d22_17_1==1)
		gen	c01_hhld_cable_TV	=	(d22_7==1)

		keep  c98_*  c01_* c06_* estudiante anio numero nper dpto region_3 region_4 secc segm ccz ///
		    trimestre mes estrato pesoano pesosem pesotri ///
			e27 e28 e31_1 e31_2 e31_3 e31_4 e31_5_1 ///
			e40 e50 f68 f88 f89_1 f89_2 f102 pt1 ///
			loc_agr educ_level ht11 d24 d26 lp_06 li_06
					
		rename (nper e27 e28 e31_1 e31_2 e31_3 e31_4 e31_5_1 ///
			e40 f68 f88 f89_1 f89_2 f102 pt1 loc_agr pesoano ///
			ht11 d24 d26) ///
			(pers hombre edad afro asia blanco indigena otro estado_civil ///
			trabajo horas_trabajo meses_trabajando ///
			anios_trabajando busca_trabajo ytotal loc pesoan ///
			y_hogar cantidad_mayores cantidad_personas)
		
		destring numero, replace
		destring anio, replace
		destring secc, replace
		destring segm, replace
		destring estrato, replace
		
		gen nomloc = ""
		gen married = (estado_civil==2)
		clean_etnia_variable
		save ..\base\clean_2007, replace
end 

program clean_08
		usespss ../raw/FUSIONADO_2008_TERCEROS.sav, clear
		
		capture rename Dpto dpto
		capture rename Trimestre trimestre
		capture rename Estrato estrato
		capture rename PT1 pt1
		capture rename HT11 ht11
		
		gen     primaria   = (e52_1>0|e52_2>0|e53_2>0|e52_7_2==3|e52_7_2==2)
		gen     secundaria = (e52_5==3|e52_6==3|(e52_7_1>=3 & e53_2==1)|e52_7_2==1)
		gen     terciaria  = (((e52_8>0|e52_9>0|e52_10>0) & e53_2==1) | e52_11>0)
		gen     educ_level = 1 if primaria>0
		replace educ_level = 2 if secundaria==1
		replace educ_level = 3 if terciaria==1
		assert e52_1+e52_2+e52_3+e52_4+e52_5+e52_6+e52_7_1+e52_8+e52_9+e52_10+e52_11==0 if educ_level ==.
		replace educ_level = 1 if educ_level==.
		
		gen estudiante = (pobpcoac == 7)

		gen	c98_resid_house		=	(c1!=5)
		gen	c06_mat_walls		=	(c2==1|c2==2)
		gen	c06_mat_roof		=	(c3==1|c3==2)
		gen	c06_mat_floor		=	(c4==1|c4==2)
		gen	c98_resid_owned		=	(d8_1==1|d8_1==2|d8_1==3|d8_1==4)
		gen	c98_nbr_rooms		=	d9
		gen	c98_nbr_bedrooms	=	d10
		gen	c98_b_piped_water	=	(d14_1==1)
		gen	c98_hhld_toilet		=	(d15==1)
		gen	c98_b_sewage		=	(d18_1==1)
		gen	c06_b_electr		=	(d19_1==1|d19_1==2)
		gen	c98_hhld_stove		=	(d20!=3)
		gen	c98_hhld_hot_water	=	(d22_1_1==1|d22_1_2==1|d22_1_3==1|d22_2_1==1|d22_2_2==1)
		gen	c98_hhld_refrigerat	=	(d22_1_2==1|d22_4==1)
		gen	c98_hhld_TV			=	(d22_5_1==1)
		gen	c98_hhld_VCR		=	(d22_8==1|d22_9==1)
		gen	c98_hhld_wash_mac	=	(d22_10==1)
		gen	c98_hhld_dishwasher	=	(d22_12==1)
		gen	c98_hhld_microwave	=	(d22_13==1)
		gen	c98_hhld_car		=	(d22_18_1==1)
		gen	c01_hhld_computer	=	(d22_14_1==1)
		gen	c01_hhld_internet	=	(d22_15_1==1|d22_15_2==1)
		gen	c01_hhld_phone		=	(d22_16_1==1|d22_17_1==1)
		gen	c01_hhld_cable_TV	=	(d22_7==1)

		keep  c98_*  c01_* c06_* estudiante anio numero nper dpto region_3 region_4 secc segm ccz ///
		    trimestre mes estrato pesoano pesosem pesotri ///
			e27 e28 e31_1 e31_2 e31_3 e31_4 e31_5_1 ///
			e40 e50 f68 f88_1 f89_1 f89_2 f102 pt1 ///
			nom_locagr educ_level ht11 d24 d26 lp_06 li_06
			
		rename(nper e27 e28 e31_1 e31_2 e31_3 e31_4 e31_5_1 ///
			e40 f68 f88_1 f89_1 f89_2 f102 pt1 nom_locagr pesoano ///
			ht11 d24 d26) ///
			(pers hombre edad afro asia blanco indigena otro estado_civil ///
			trabajo horas_trabajo meses_trabajando ///
			anios_trabajando busca_trabajo ytotal nomloc pesoan ///
			y_hogar cantidad_mayores cantidad_personas)

		destring numero, replace
		destring anio, replace
		destring secc, replace
		destring segm, replace
		destring estrato, replace
		
	    gen loc = ""
		gen married = (estado_civil==2)		
		clean_etnia_variable
		save ..\base\clean_2008, replace
end 

program clean_09_16

    forval year=2009/2016 {
		if "`year'" == "2016" {
			usespss ../raw/HyP_`year'_TERCEROS.sav, clear
			}
			else {
		    usespss ../raw/FUSIONADO_`year'_TERCEROS.sav, clear
		}
		
		capture rename estratogeo09 estrato
		capture rename estratogeo estrato
		capture rename estred13 estrato
		capture rename PT1 pt1
		capture rename HT11 ht11		
		capture rename Loc_agr_13 locagr
		capture rename Nom_loc_agr_13 nom_locagr
		capture rename POBPCOAC pobpcoac
		
		capture gen trimestre = 1 if inlist(mes, 1, 2, 3)
		capture replace trimestre = 2 if inlist(mes, 4, 5, 6)
		capture replace trimestre = 3 if inlist(mes, 7, 8, 9)
		capture replace trimestre = 4 if inlist(mes, 10, 11, 12)
		capture gen pesosem = .
		capture gen pesotri = .

		if "`year'" <= "2010" {
				gen     primaria   = (e51_1>0|e51_2>0|e51_3>0|e51_4>0)
				gen     secundaria = (e51_5==3|e51_6==3|(e51_7>=3 & e53==1)|e51_7_1==1)
				gen     terciaria  = (((e51_8>0|e51_9>0|e51_10>0) & e53==1) | e51_11>0)

				gen     educ_level = 1 if primaria>0
				replace educ_level = 2 if secundaria==1
				replace educ_level = 3 if terciaria==1
				assert e51_1+e51_2+e51_3+e51_4+e51_5+e51_6+e51_7_1+e51_8+e51_9+e51_10+e51_11==0 if educ_level ==.
				replace educ_level = 1 if educ_level==.	
			}
			else {
				gen     primaria   = (e193!=3|e197!=3|e201_1==2|e212_1==2)
				gen     secundaria = (e201_1==1|e212_1==1|e215_1==2|e218_1==2|e218_1==2|e221_1==2|e224_1==2)
				gen     terciaria  = (e215_1==1|e218_1==1|e218_1==1|e221_1==1|e224_1==1)
				gen     educ_level = 1 if primaria==1
				replace educ_level = 2 if secundaria==1
				replace educ_level = 3 if terciaria==1
				assert  e193==3        if educ_level==.
				assert e197_1+e201_+e212_1+e215_1+e218_1+e218_1+e221_1+e224_1==0 if educ_level==.
				replace educ_level = 1 if educ_level==. 		    
		}
		
		gen estudiante = (pobpcoac == 7)
		
		gen	c98_resid_house		=	(c1!=5)
		gen	c06_mat_walls		=	(c2==1|c2==2)
		gen	c06_mat_roof		=	(c3==1|c3==2)
		gen	c06_mat_floor		=	(c4==1|c4==2)
		gen	c98_resid_owned		=	(d8_1==1|d8_1==2|d8_1==3|d8_1==4)
		gen	c98_nbr_rooms		=	d9
		gen	c98_nbr_bedrooms	=	d10
		gen	c98_b_piped_water	=	(d12==1)
		gen	c98_hhld_toilet		=	(d13==1)
		gen	c98_b_sewage		=	(d16==1)
		gen	c06_b_electr		=	(d18==1)
		gen	c98_hhld_stove		=	(d19!=3)
		gen	c98_hhld_hot_water	=	(d21_1==1|d21_2==1)
		gen	c98_hhld_refrigerat	=	(d21_3==1)
		gen	c98_hhld_TV			=	(d21_4==1|d21_5==1)
		gen	c98_hhld_VCR		=	(d21_8==1|d21_9==1)
		gen	c98_hhld_wash_mac	=	(d21_10==1)
		gen	c98_hhld_dishwasher	=	(d21_12==1)
		gen	c98_hhld_microwave	=	(d21_13==1)
		gen	c98_hhld_car		=	(d21_18==1)
		gen	c01_hhld_computer	=	(d21_15==1)
		gen	c01_hhld_internet	=	(d21_16==1)
		gen	c01_hhld_phone		=	(d21_17	==1)
		gen	c01_hhld_cable_TV	=	(d21_7==1)

		keep c98_*  c01_* c06_* estudiante anio numero nper dpto region_3 region_4 secc segm ccz* ///
		    trimestre mes estrato pesoano pesosem pesotri ///
			e26 e27 e29_6 e36 e49 f66 f85 f88_1 f88_2 f99 pt1 ///
			locagr nom_locagr educ_level ht11 d23 d25 lp_06 li_06
			
		rename (nper e26 e27 e29_6 e36 f66 f85 f88_1 f88_2 f99 pt1 locagr ///
		    nom_locagr pesoano ht11 d23 d25) ///
			(pers hombre edad ascendencia estado_civil trabajo ///
			horas_trabajo meses_trabajando anios_trabajando busca_trabajo ///
			ytotal loc nomloc pesoan y_hogar cantidad_mayores cantidad_personas)
		
		destring numero, replace
		destring anio, replace
		destring secc, replace
		destring segm, replace
		destring estrato, replace
		
		gen married = (estado_civil==3)	
		gen etnia = ascendencia
		replace etnia=0 if ascendencia==5
		save ..\base\clean_`year', replace
		}
end

main_clean_raw
