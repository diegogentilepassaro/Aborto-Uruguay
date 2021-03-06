clear all
set more off
adopath + ../../../library/stata/gslab_misc/ado

program main    
    append_years
    gen_vars
    label_vars

    gen birth_id = _n
    drop if missing(dpto)
    keep birth_id anio anio_sem anio_qtr dpto dpto_residence tipoestab ///
        edadm young adult age_group married not_married partner no_partner single ///
        prim_school high_school recomm_prenatal_numvisits ///
        recomm_prenatal_1stvisit no_prenatal_care first_pregnancy kids_before ///
        lowbirthweight apgar1_low apgar2_low preg_preterm 
    save_data ../output/vital_birth_records.dta, key(birth_id) replace
end

program append_years
    * Note: there is no 1998 data, but there is data for 1996 and 1997
    forvalues year = 1999/2015 {
        capture import delimited "../../../raw/vital_records/Natalidad `year'_p.csv", delim(";") clear

        qui destring , replace
        
        tempfile temp_`year'
        save `temp_`year''
    }

    forvalues year = 1999/2014 {
        append using `temp_`year''
    }

    keep if inrange(anio_parto,1999,2015) //note some births in 2015 are recorded in 2016
    
    save "../temp/births_append.dta", replace
end

program gen_vars
    use "../temp/births_append.dta", clear
    rename anio_parto anio

    * Add variable dpto coded as in the ECH
    gen     dpto = codep   if inrange(codep,11,19)
    replace dpto = 1       if codep==10
    replace dpto = codep+1 if inrange(codep,1,9)
    drop codep
    
    gen     dpto_residence = depar   if inrange(depar,11,19)
    replace dpto_residence = 1       if depar==10
    replace dpto_residence = depar+1 if inrange(depar,1,9)
    drop depar

    * Assert that corresponding variables are not used at the same time & Gen harmonized vars
    * Note: issue with mademay == 4 : table anio madeult if mademay == 4
    assert (mi(civilm) & !mi(mestciv) & !mi(tunion)) | (!mi(civilm) & mi(mestciv) & mi(tunion))
    assert (mi(instm) & !mi(mademay) & !mi(madecur) & !mi(madeult)) | (!mi(instm) & mi(mademay) & mi(madecur) & mi(madeult))
    gen married     = (civilm==2 | mestciv==2)                           if civilm!=9 & mestciv!=9
    gen not_married = (married==0)                                       if !mi(married)
    gen partner     = (inlist(civilm,2,3)|mestciv==2|inlist(tunion,1,2)) if civilm!=9 & mestciv!=9
    gen no_partner  = (partner==0)                                       if !mi(partner)
    gen single      = (inlist(civilm,1,4,5,6))|(tunion==9|mestciv==2)    if civilm!=9 & mestciv!=9 
    gen     prim_school = (instm==2|((mademay==2 & madeult==6)|(mademay==4 & madeult<3)|mademay==3)) if instm!=9 | mademay!=9 | madeult!=9
    gen     high_school = (instm==3|((mademay==4 & madeult==3)|(mademay==5 & madeult==1)))           if instm!=9 | mademay!=9 | madeult!=9
    replace high_school = 1 if inrange(anio,2008,2010) & mademay==4 & madeult==6 
    
    * Birth date
    drop if mi(fecparto)
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
    gen recomm_prenatal_numvisits = (totcons>5) if !mi(totcons) & totcons!=99
    gen recomm_prenatal_1stvisit  = (semprim<13) if !inlist(semprim,97,99)
    gen no_prenatal_care          = (totcons==0 | semprim==97) if totcons!=99
    gen first_pregnancy           = (numemban==0) if numemban!=99
    gen kids_before               = (first_pregnancy==0) if !mi(first_pregnancy)
    gen lowbirthweight            = (peso<2500) if !mi(peso)   & peso<9999
    gen apgar1_low                = (apgar1<7)  if !mi(apgar1) & inrange(apgar1,1,10)
    gen apgar2_low                = (apgar2<7)  if !mi(apgar2) & inrange(apgar2,1,10)
    gen preg_preterm              = (semgest<37) if !mi(semgest) & semgest!=99

    * age vars
    gen young         = inrange(edadm,16,30)
    gen adult         = inrange(edadm,31,45)
    egen age_group    = cut(edadm) , at(16(5)45)
    replace age_group = age_group+2

    lab def young                 0 "Age: 31-45"             1 "Age: 16-30"
    lab val young                 young    
end

program label_vars
    lab def not_married               0 "Married"                1 "Not married"
    lab val not_married               not_married
    lab def no_partner                0 "With partner"           1 "Without partner"
    lab val no_partner                no_partner
    lab def prim_school               0 "Less than PS"           1 "PS or more"
    lab val prim_school               prim_school
    lab def high_school               0 "Less than HS"           1 "HS or more"
    lab val high_school               high_school
    lab def no_prenatal_care          1 "No prenatal care"       0 "Prenatal care"
    lab val no_prenatal_care          no_prenatal_care
    lab def lowbirthweight            1 "Low birth weight"       0 "Normal birth weight"
    lab val lowbirthweight            lowbirthweight
    lab def apgar1_low                1 "Low APGAR score"        0 "Normal APGAR score"
    lab val apgar1_low                apgar1_low
    lab def apgar2_low                1 "Low APGAR score"        0 "Normal APGAR score"
    lab val apgar2_low                apgar2_low
    lab def preg_preterm              1 "Pre-term birth"         0 "Full-term birth"
    lab val preg_preterm              preg_preterm
    lab def first_pregnancy           0 "Not first pregnancy"    1 "First pregnancy"
    lab val first_pregnancy           first_pregnancy
    lab def recomm_prenatal_numvisits 0 "No prenatal care"       1 "Prenatal care"
    lab val recomm_prenatal_numvisits recomm_prenatal_numvisits
    lab def recomm_prenatal_1stvisit  0 "No prenatal care"       1 "Prenatal care"
    lab val recomm_prenatal_1stvisit  recomm_prenatal_1stvisit
    label_geo
end

program label_geo
    label var    dpto "Mother's residential state"
    label define dpto  1 "ARTIGAS" ///
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
    label values dpto dpto
    label values dpto_residence dpto
end

main
