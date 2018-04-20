clear all
set more off

program main	
	append_data
	derived_data
end

program append_data
	* Note: there is no 1998 data, but there is data for 1996 and 1997
	forvalues year = 1999/2015 {
		capture import delimited "..\..\raw\vital_records\Natalidad `year'_p.csv", delim(";") clear
		
		*capture rename (civilm  civilp  instm   instp) (mestciv pestciv mademay pademay)
						 
		qui destring , replace
		
		tempfile temp_`year'
		save `temp_`year''
	}

	forvalues year = 1999/2014 {
		append using `temp_`year''
	}

	keep if inrange(anio_parto,1999,2015) //note some births in 2015 are recorded in 2016
	assert !mi(edadm)
	*keep if inrange(edadm,16,45)
	
	save "..\temp\births_append.dta", replace
end

program derived_data
	use "..\temp\births_append.dta", clear
	rename anio_parto anio

	* Assert that corresponding variables are not used at the same time & Gen harmonized vars
	* Note: issue with mademay == 4 : table anio madeult if mademay == 4
	assert (mi(civilm) & !mi(mestciv) & !mi(tunion)) | (!mi(civilm) & mi(mestciv) & mi(tunion))
	assert (mi(instm) & !mi(mademay) & !mi(madecur) & !mi(madeult)) | (!mi(instm) & mi(mademay) & mi(madecur) & mi(madeult))
	gen married = (civilm==2 | mestciv==2)
	gen not_married = (married==0)
	gen partner = (civilm==2|civilm==3|mestciv==2|(convpad==1 & (tunion==1|tunion==2)))
	gen no_partner = (partner==0)
	gen prim_school = (instm==2 | ((mademay==2 & madeult==6) | (mademay==4 & madeult<3) | mademay==3))
	gen high_school = (instm==3 | ((mademay==4 & madeult==3) | (mademay==5 & madeult==1)))
	replace high_school = 1 if inrange(anio,2008,2010) & mademay==4 & madeult==6
	
	* Birth date
	replace fecparto = "jan" + substr(fecparto,4, .) if substr(fecparto, 1, 3) == "ene"
	replace fecparto = "apr" + substr(fecparto,4, .) if substr(fecparto, 1, 3) == "abr"
	replace fecparto = "aug" + substr(fecparto,4, .) if substr(fecparto, 1, 3) == "ago"
	replace fecparto = "dec" + substr(fecparto,4, .) if substr(fecparto, 1, 3) == "dic"
	gen     anio_mon = monthly(fecparto, "MY")
	replace anio_mon = monthly(fecparto, "M20Y")
	assert !mi(anio_mon) if !mi(fecparto)
	format  anio_mon %tm 
	gen     anio_qtr = qofd(dofm(anio_mon))
    format  anio_qtr %tq
	gen     anio_sem = hofd(dofm(anio_mon))
	format  anio_sem %th
	
	* Pregnancy vars
	gen recomm_prenatal_numvisits = (totcons>5 & totcon!=99)
	gen recomm_prenatal_1stvisit  = (semprim<13 & semprim!=97 & semprim!=99)
	gen no_prenatal_care          = (totcons==0 | totcon==99 | semprim==97 | semprim==99)
	gen first_pregnancy           = (numemban==0)
	
	* Add variable dpto coded as in the ECH
	gen     dpto = depar   if inrange(depar,11,19)
	replace dpto = 1       if depar==10
	replace dpto = depar+1 if inrange(depar,1,9)
	
	* Labelling
	lab def not_married               0 "Married"                1 "Not married"
	lab val not_married               not_married
	lab def no_partner                0 "With partner"           1 "Without partner"
	lab val no_partner                no_partner
	lab def prim_school               0 "Less than PS"           1 "PS or more"
	lab val prim_school               prim_school
	lab def high_school               0 "Less than HS"           1 "HS or more"
	lab val high_school               high_school
	lab def no_prenatal_care          0 "No prenatal care"       1 "Prenatal care"
	lab val no_prenatal_care          no_prenatal_care
	lab def first_pregnancy           0 "Not first pregnancy"    1 "First pregnancy"
	lab val first_pregnancy           first_pregnancy
	lab def recomm_prenatal_numvisits 0 "5 or less"              1 "More than 5"
	lab val recomm_prenatal_numvisits recomm_prenatal_numvisits
	lab def recomm_prenatal_1stvisit  0 "1st visit by 14+ weeks" 1 "1st visit by 13 weeks"
	lab val recomm_prenatal_1stvisit  recomm_prenatal_1stvisit
	label_depar

	save "..\output\births_derived.dta", replace
end

program label_depar
	label var    depar "Mother's residential state"
	label define depar  1 "ARTIGAS" ///
						2 "CANELONES" ///
						3 "CERRO LARGO" ///
						4 "COLONIA" ///
						5 "DURAZNO" ///
						6 "FLORES" ///
						7 "FLORIDA" ///
						8 "LAVALLEJA" ///
						9 "MALDONADO" ///
						10 "MONTEVIDEO" ///
						11 "PAYSANDU" ///
						12 "RÍO NEGRO" ///
						13 "RIVERA" ///
						14 "ROCHA" ///
						15 "SALTO" ///
						16 "SAN JOSÉ" ///
						17 "SORIANO" ///
						18 "TACUAREMBÓ" ///
						19 "TREINTA Y TRES"
	label values depar depar
end

main
