clear all
set more off

program main_clean_raw
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
                    import excel using "..\..\raw/`year'/`t'`year's`w'`c'.xls", clear first
                    tempfile temp_`t'_`w'`c'
                    save `temp_`t'_`w'`c''
                    }
                append using `temp_`t'_`w'i'
                tempfile temp_`t'_`w'
                save `temp_`t'_`w''
                }
            append using `temp_`t'_1'
            save ..\temp\preclean_`year'_`t'.dta, replace
        }
         use ..\temp\preclean_`year'_p.dta, clear

         rename correlativ ident
         merge m:1 ident using ..\temp\preclean_`year'_h.dta, nogen
         save ..\temp\preclean_`year'.dta, replace
    }
    
end

program clean_98_00
    * Note: can't find: afro asia blanco indigena otro then generated raza equal missing
    forvalues year=1998/2000 {
        use ..\temp\preclean_`year'.dta, replace        
        
        rename (ident     persona   pe1        pe1a        pe1b   ///
                pe1c      pe1d      pe1e       pe1h        locech ///
                nomlocech ht11      hd21       hd22        ht3   ///
                pe2       pe3       pt1 ///
                pf37                pf06                   pf051 ///
                pf38                pf351                  pf052)        ///
               (numero    pers      nper       anio        semana ///
                dpto      secc      segm       estrato     loc    ///
                nomloc    y_hogar   nbr_people nbr_above14 nbr_under14 ///
                hombre    edad      ytotal ///
                meses_trabajando    horas_trabajo          horas_trabajo_p  ///
                anios_trabajando    busca_trabajo          horas_trabajo_s)

        replace pobpcoac = 1  if pobpcoac==40
        replace pobpcoac = 2  if inlist(pobpcoac,11,12)
        replace pobpcoac = 3  if pobpcoac==23
        replace pobpcoac = 4  if pobpcoac==21
        replace pobpcoac = 5  if pobpcoac==22
        replace pobpcoac = 6  if pobpcoac==34
        replace pobpcoac = 7  if pobpcoac==33
        replace pobpcoac = 8  if pobpcoac==32
        replace pobpcoac = 9  if pobpcoac==30
        replace pobpcoac = 10 if pobpcoac==31
        replace pobpcoac = 11 if inlist(pobpcoac,35,36,37,38)

        gen    c98_resid_house        =    (hc1==1)
        gen    c98_resid_owned        =    (hd3==1|hd3==2)
        gen    c98_nbr_rooms        =    hd41
        gen    c98_nbr_bedrooms    =    hd42
        gen    c98_b_piped_water    =    (hd6==1)
        gen    c98_hhld_toilet        =    (hd7==1)
        gen    c98_b_sewage        =    (hd9==1)
        gen    c98_hhld_stove        =    (hd102!=7)
        gen    c98_hhld_hot_water    =    (hd111==1)
        gen    c98_hhld_refrigerat    =    (hd112==1|hd113==1)
        gen    c98_hhld_tv            =    (hd114==1|hd115==1)
        gen    c98_hhld_vcr        =    (hd116==1)
        gen    c98_hhld_wash_mac    =    (hd117==1)
        gen    c98_hhld_dishwasher    =    (hd118==1)
        gen    c98_hhld_microwave    =    (hd119==1)
        gen    c98_hhld_car        =    (hd1110==1)
        
        gen     trimestre = 1 if inrange(semana, 1, 12)
        replace trimestre = 2 if inrange(semana, 13, 24)
        replace trimestre = 3 if inrange(semana, 25, 36)
        replace trimestre = 4 if inrange(semana, 37, 48)

        gen married = (pe5==1|pe5==2)
        gen etnia = .
        
        gen estudiante = (pobpcoac==33)
        gen trabajo    = (pobpcoac==2)
        bysort numero: egen y_hogar_alt = sum(ytotal) 
        
        gen anios_prim = clip(pe142,0,6) if pe141 == 1
        replace anios_prim = 6 if inlist(pe141,2,3,4,5,6)

        gen anios_secun = pe142 if pe141 == 2
        replace anios_secun = pe142 + 3  if pe141 == 3
        replace anios_secun = 6 if anios_secun > 6 & !missing(anios_secun)    
        replace anios_secun = 6 if inlist(pe141,5,6)
        
        gen anios_terc = pe142 if (pe141 == 5 | pe141 == 6)
        
        gen anios_tecn = pe142 if pe141 == 4
        
        replace anios_secun = 0 if missing(anios_secun) & !missing(anios_prim)
        replace anios_terc = 0 if missing(anios_terc) & ///
            (!missing(anios_prim) | !mi(anios_secun))
        replace anios_tecn = 0 if missing(anios_tecn) & ///
            (!missing(anios_prim) | !mi(anios_secun))

        gen educ_level = 1 if (anios_secun == 0 & anios_tecn == 0)
        replace educ_level = 2 if inlist(anios_secun,1,2,3,4,5) | ///
            inlist(anios_tecn,1,2,3,4,5)
        replace educ_level = 3 if (anios_secun == 6 & !missing(anios_secun) | ///
            anios_tecn >= 6 & !missing(anios_tecn))
        replace educ_level = 4 if (anios_terc > 0 & !missing(anios_terc))
                
        assert nper==pers
        drop nper

        keep numero pers anio trimestre semana dpto secc segm estrato loc nomloc ccz ///
                peso* hombre edad ytotal y_hogar* nbr_people nbr_above14 nbr_under14 ///
                pobpcoac married etnia c98_* estudiante educ_level anios_* *trabaj*

        save ..\temp\clean_`year'.dta, replace
        }
end

program clean_01_05
    * Note: there is no nomdepto for 2005: check running table nomdpto anio
    * Can't find: meses_trabajando anios_trabajando
    
    foreach year in 2001 2002 2003 2004 2005 {
        foreach t in p h {
            import excel using "..\..\raw/`year'/`t'`year'.xls", clear first
            save ..\temp\preclean_`year'_`t'.dta, replace
        }
        use ..\temp\preclean_`year'_p.dta, clear

        merge m:1 correlativ using ..\temp\preclean_`year'_h.dta, nogen
        save ..\temp\preclean_`year'.dta, replace
    }
    foreach year in 2001 2002 2003 2004 2005 {
        use ..\temp\preclean_`year'.dta, clear
        
        rename (correlativ nper  locech          nomlocech ///
                e1         e2    pt1             ht11 ///
                f17_1            f17_2           f1_1      f23 ///
                d14              d16             ht3) ///               
               (numero     pers  loc             nomloc ///
                hombre     edad  ytotal          y_hogar ///
                horas_trabajo_p  horas_trabajo_s trabajo_1 busca_trabajo ///
                nbr_above14      nbr_people      nbr_under14)

        gen    c98_resid_house        =    (c1==1)
        gen    c98_resid_owned        =    (d2==1|d2==2)
        gen    c98_nbr_rooms        =    d3
        gen    c98_nbr_bedrooms    =    d4
        gen    c98_b_piped_water    =    (d6==1)
        gen    c98_hhld_toilet        =    (d7==1)
        gen    c98_b_sewage        =    (d8==1)
        gen    c98_hhld_stove        =    (d9!=5)
        gen    c98_hhld_hot_water    =    (d10_1==1|d10_2==1)
        gen    c98_hhld_refrigerat    =    (d10_3==1)
        gen    c98_hhld_tv            =    (d10_4==1)
        gen    c98_hhld_vcr        =    (d10_6==1)
        gen    c98_hhld_wash_mac    =    (d10_7==1)
        gen    c98_hhld_dishwasher    =    (d10_8==1)
        gen    c98_hhld_microwave    =    (d10_9==1)
        gen    c98_hhld_car        =    (d10_12==1)
        gen    c01_hhld_computer    =    (d10_10==1)
        gen    c01_hhld_internet    =    (d10_11==1)
        gen    c01_hhld_phone        =    (d10_13==1)
        gen    c01_hhld_cable_tv    =    (d10_5==1)
             
        capture gen     trimestre = 1 if inlist(mes, 1, 2, 3)
        capture replace trimestre = 2 if inlist(mes, 4, 5, 6)
        capture replace trimestre = 3 if inlist(mes, 7, 8, 9)
        capture replace trimestre = 4 if inlist(mes, 10, 11, 12)
        
        gen married = (e4==1|e4==2)
        gen etnia = .

        gen estudiante = (pobpcoac==7)
        gen trabajo    = (pobpcoac==2)
        bysort numero: egen y_hogar_alt = sum(ytotal) 
        gen horas_trabajo =  horas_trabajo_p + horas_trabajo_s
        gen meses_trabajando = .
        gen anios_trabajando = .

        gen anios_prim = clip(e11_2,0,6) if (e9 == 1 | e10 == 1)

        gen anios_secun = clip(e11_3, 0, 6) if (e9 == 1 | e10 == 1)
        
        gen anios_terc = e11_5 + e11_6 if (e9 == 1 | e10 == 1)
        
        gen anios_tecn = e11_4 if (e9 == 1 | e10 == 1)
        
        replace anios_secun = 0 if missing(anios_secun) & !missing(anios_prim)
        replace anios_terc = 0 if missing(anios_terc) & ///
            (!missing(anios_prim) | !mi(anios_secun))
        replace anios_terc = 0 if anios_secun != 6    
        replace anios_tecn = 0 if missing(anios_tecn) & ///
            (!missing(anios_prim) | !mi(anios_secun))

        gen educ_level = 1 if (anios_secun == 0 & anios_tecn == 0)
        replace educ_level = 2 if inlist(anios_secun,1,2,3,4,5) | ///
            inlist(anios_tecn,1,2,3,4,5)
        replace educ_level = 3 if (anios_secun == 6 & !missing(anios_secun) | ///
            anios_tecn >= 6 & !missing(anios_tecn))
        replace educ_level = 4 if (anios_terc > 0 & !missing(anios_terc))
        
        keep numero pers anio trimestre mes dpto secc segm estrato loc nomloc ccz ///
             peso* hombre edad ytotal y_hogar* nbr_people nbr_above14 nbr_under14 ///
             pobpcoac married etnia c98_* c01_* estudiante educ_level anios_* *trabaj*
        
        save ..\temp\clean_`year'.dta, replace
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
        use ../temp/raw_2006.dta, clear
        
        capture rename Dpto dpto
        capture rename Trimestre trimestre
        capture rename Estrato estrato
        capture rename PT1 pt1
        capture rename HT11 ht11
        capture rename HT3 ht3
        capture rename Pobpcoac pobpcoac

        rename (nper  locagr nom_locagr e27  e26    pesoano  pt1              ht11             ///
                f62          f81             f93             f82_1            f82_2            ///
                d23          d25             ht3             f102                              ///
                e38          e39_1           e30_1  e30_2    e30_3  e30_4     e30_5_2)        ///
               (pers   loc   nomloc     edad hombre pesoan   ytotal     y_hogar                ///
                trabajo_1    horas_trabajo_p horas_trabajo_s meses_trabajando anios_trabajando ///
                nbr_above14  nbr_people      nbr_under14     busca_trabajo                     ///
                live_births  live_births_nbr afro   asia     blanco indigena  otro)

        gen    c98_resid_house        =    (c1!=5)
        gen    c06_mat_walls        =    (c2==1|c2==2)
        gen    c06_mat_roof        =    (c3==1|c3==2)
        gen    c06_mat_floor        =    (c4==1|c4==2)
        gen    c98_resid_owned        =    (d7_1==1|d7_1==2|d7_1==3|d7_1==4)
        gen    c98_nbr_rooms        =    d8
        gen    c98_nbr_bedrooms    =    d9
        gen    c98_b_piped_water    =    (d13==1)
        gen    c98_hhld_toilet        =    (d14==1)
        gen    c98_b_sewage        =    (d17==1)
        gen    c06_b_electr        =    (d18_1==1|d18_1==2)
        gen    c98_hhld_stove        =    (d19!=3)
        gen    c98_hhld_hot_water    =    (d21_1_1==1|d21_1_2==1|d21_1_3==1|d21_2_1==1|d21_2_2==1)
        gen    c98_hhld_refrigerat    =    (d21_3==1|d21_4==1)
        gen    c98_hhld_tv            =    (d21_5_1==1)
        gen    c98_hhld_vcr        =    (d21_8==1|d21_9==1)
        gen    c98_hhld_wash_mac    =    (d21_10==1)
        gen    c98_hhld_dishwasher    =    (d21_12==1)
        gen    c98_hhld_microwave    =    (d21_13==1)
        gen    c98_hhld_car        =    (d21_18_1==1)
        gen    c01_hhld_computer    =    (d21_14_1==1)
        gen    c01_hhld_internet    =    (d21_15==1)
        gen    c01_hhld_phone        =    (d21_16_1==1|d21_17_1==1)
        gen    c01_hhld_cable_tv    =    (d21_7==1)
        
        gen married  = (e34==1|e37==2) if e34!=0
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

        gen estudiante = (pobpcoac == 7)
        gen trabajo    = (pobpcoac == 2)
        bysort numero: egen y_hogar_alt = sum(ytotal) 
        gen horas_trabajo =  horas_trabajo_p + horas_trabajo_s
        
        gen anios_prim = (e50_2 + e50_3) if e48 == 1 & (e50_4 == 0 & e50_5 == 0 & ///
            e50_6 == 0 & e50_7 == 0 & e50_8 == 0 & e50_9 == 0 & e50_10 == 0 & ///
            e50_11 == 0 & e50_12 == 0)
        replace anios_prim = 6 if e48 == 1 & (e50_4 > 0 | e50_5 > 0 | ///
            e50_6 > 0 | e50_7 > 0 | e50_8 > 0 | e50_9 > 0 | e50_10 > 0 | ///
            e50_11 > 0 | e50_12 > 0)
        replace anios_prim = e52_1_1 if e48 == 2 & e51 == 1 
        replace anios_prim = (e52_1_1 - 1) if e48 == 2 & e51 == 1 & ///
            e52_1_1 == 6 & e52_1_2 == 2
        replace anios_prim = 6 if e52_3_3 == 1 | e52_3_3 == 2 | e52_3_3 == 3
            
        gen anios_secun = (e50_4 + e50_6) if e48 == 1 & ///
            (e50_9 == 0 & e50_10 == 0 & e50_11 == 0 & e50_12 == 0)
        replace anios_secun = 6 if e48 == 1 & (e50_9 > 0 | e50_10 > 0 | ///
            e50_11 > 0 | e50_12 > 0)    
        replace anios_secun = e52_2_1 if e48 == 2 & e51 == 1 
        replace anios_secun = (e52_2_1 - 1) if e48 == 2 & e51 == 1 & ///
            e52_2_1 == 6 & e52_2_2 == 2
        
        gen anios_terc = (e50_9 + e50_10 + e50_11 + e50_12) if e48 == 1 & ///
            (e50_9 > 0 | e50_10 > 0 | e50_11 > 0 | e50_12 > 0)
        replace anios_terc = (e52_4_1 + e52_5_1 + e52_6_1 + e52_7_1) ///
            if e48 == 2 & e51 == 1
        
        gen anios_tecn = (e50_5 + e50_7 + e50_8) if e48 == 1 & ///
            (e50_9 == 0 & e50_10 == 0 & e50_11 == 0 & e50_12 == 0)
        replace anios_tecn = 6 if e48 == 1 & (e50_9 > 0 | e50_10 > 0 | ///
            e50_11 > 0 | e50_12 > 0)
        replace anios_tecn = e52_3_1 if e48 == 2 & e51 == 1 
        replace anios_tecn = (e52_3_1 - 1) if e48 == 2 & e51 == 1 & ///
            e52_3_1 == 6 & e52_3_2 == 2
        replace anios_tecn = 6 if e52_3_3 == 1
        replace anios_tecn = 3 if e52_3_3 == 2
        
        replace anios_prim = 6 if anios_secun > 0 & anios_prim == 0
        replace anios_prim = 6 if anios_terc > 0 & anios_prim == 0
        replace anios_secun = 6 if anios_terc > 0 & anios_secun == 0
        
        gen educ_level = 1 if (anios_secun == 0 & anios_tecn == 0)
        replace educ_level = 2 if inlist(anios_secun,1,2,3,4,5) | ///
            inlist(anios_tecn,1,2,3,4,5)
        replace educ_level = 3 if (anios_secun == 6 & !missing(anios_secun) | ///
            anios_tecn >= 6 & !missing(anios_tecn))
        replace educ_level = 4 if (anios_terc > 0 & !missing(anios_terc))

        destring anio, replace
        destring secc, replace
        destring segm, replace
        destring estrato, replace

        keep numero pers anio trimestre mes dpto secc segm estrato loc nomloc ccz    ///
             peso* hombre edad ytotal y_hogar* nbr_people nbr_above14 nbr_under14    ///
             pobpcoac married etnia c98_* c01_* c06_* estudiante educ_level anios_* *trabaj* ///
             lp_06 li_06 region_3 region_4 live_births*
        save ..\temp\clean_2006, replace    
end

program clean_07
        use ../temp/raw_2007.dta, clear
        
        capture rename Dpto dpto
        capture rename Trimestre trimestre
        capture rename Estrato estrato
        capture rename PT1  pt1
        capture rename HT11 ht11
        capture rename HT3  ht3
        capture rename Pobpcoac pobpcoac
                    
        rename (nper loc_agr pesoano e27      e28   pt1       ht11                              ///
                f68          f88              f101            f89_1            f89_2            ///
                d24          d26              ht3             f102                              ///
                e41          e42_1            e31_1 e31_2     e31_3   e31_4    e31_5_1)         ///
               (pers loc     pesoan  hombre   edad  ytotal    y_hogar                           ///
                trabajo_1    horas_trabajo_p  horas_trabajo_s meses_trabajando anios_trabajando ///
                nbr_above14  nbr_people       nbr_under14     busca_trabajo                     ///
                live_births  live_births_nbr  afro  asia      blanco  indigena otro)

        gen    c98_resid_house        =    (c1!=5)
        gen    c06_mat_walls        =    (c2==1|c2==2)
        gen    c06_mat_roof        =    (c3==1|c3==2)
        gen    c06_mat_floor        =    (c4==1|c4==2)
        gen    c98_resid_owned        =    (d8_1==1|d8_1==2|d8_1==3|d8_1==4)
        gen    c98_nbr_rooms        =    d9
        gen    c98_nbr_bedrooms    =    d10
        gen    c98_b_piped_water    =    (d14_1==1)
        gen    c98_hhld_toilet        =    (d15==1)
        gen    c98_b_sewage        =    (d18_1==1)
        gen    c06_b_electr        =    (d19_1==1|d19_1==2)
        gen    c98_hhld_stove        =    (d20!=3)
        gen    c98_hhld_hot_water    =    (d22_1_1==1|d22_1_2==1|d22_1_3==1|d22_2_1==1|d22_2_2==1)
        gen    c98_hhld_refrigerat    =    (d22_1_2==1|d22_4==1)
        gen    c98_hhld_tv            =    (d22_5_1==1)
        gen    c98_hhld_vcr        =    (d22_8==1|d22_9==1)
        gen    c98_hhld_wash_mac    =    (d22_10==1)
        gen    c98_hhld_dishwasher    =    (d22_12==1)
        gen    c98_hhld_microwave    =    (d22_13==1)
        gen    c98_hhld_car        =    (d22_18_1==1)
        gen    c01_hhld_computer    =    (d22_14_1==1)
        gen    c01_hhld_internet    =    (d22_15_1==1|d22_15_2==1)
        gen    c01_hhld_phone        =    (d22_16_1==1|d22_17_1==1)
        gen    c01_hhld_cable_tv    =    (d22_7==1)
        
        gen married  = (e37==1|e40==2) if e37!=0
        clean_etnia_variable
        
        gen estudiante = (pobpcoac == 7)
        gen trabajo    = (pobpcoac == 2)
        bysort numero: egen y_hogar_alt = sum(ytotal) 
        gen horas_trabajo =  horas_trabajo_p + horas_trabajo_s
        
        gen anios_prim = (e52_2 + e52_3) if e50 == 1 & (e52_4 == 0 & e52_5 == 0 & ///
            e52_5 == 0 & e52_7 == 0 & e52_8 == 0 & e52_9 == 0 & e52_10 == 0 & ///
            e52_11 == 0 & e52_12 == 0)
        replace anios_prim = 6 if e50 == 1 & (e52_4 > 0 | e52_5 > 0 | ///
            e52_6 > 0 | e52_7 > 0 | e52_8 > 0 | e52_9 > 0 | e52_10 > 0 | ///
            e52_11 > 0 | e52_12 > 0)
        replace anios_prim = e54_1_1 if e50 == 2 & e53 == 1 
        replace anios_prim = (e54_1_1 - 1) if e50 == 2 & e53 == 1 & ///
            e54_1_1 == 6 & e54_1_2 == 2
        replace anios_prim = 6 if e54_3_3 == 1 | e54_3_3 == 2 | e54_3_3 == 3
            
        gen anios_secun = (e52_4 + e52_5) if e50 == 1 & ///
            (e52_9 == 0 & e52_10 == 0 & e52_11 == 0 & e52_12 == 0)
        replace anios_secun = 6 if e50 == 1 & (e52_9 > 0 | e52_10 > 0 | ///
            e52_11 > 0 | e52_12 > 0)    
        replace anios_secun = e54_2_1 if e50 == 2 & e53 == 1 
        replace anios_secun = (e54_2_1 - 1) if e50 == 2 & e53 == 1 & ///
            e54_2_1 == 6 & e54_2_2 == 2
        
        gen anios_terc = (e52_9 + e52_10 + e52_11 + e52_12) if e50 == 1 & ///
            (e52_9 > 0 | e52_10 > 0 | e52_11 > 0 | e52_12 > 0)
        replace anios_terc = (e54_4_1 + e54_5_1 + e54_6_1 + e54_7_1) ///
            if e50 == 2 & e53 == 1
        
        gen anios_tecn = (e52_5 + e52_7 + e52_8) if e50 == 1 & ///
            (e52_9 == 0 & e52_10 == 0 & e52_11 == 0 & e52_12 == 0)
        replace anios_tecn = 6 if e50 == 1 & (e52_9 > 0 | e52_10 > 0 | ///
            e52_11 > 0 | e52_12 > 0)
        replace anios_tecn = e54_3_1 if e50 == 2 & e53 == 1 
        replace anios_tecn = (e54_3_1 - 1) if e50 == 2 & e53 == 1 & ///
            e54_3_1 == 6 & e54_3_2 == 2
        replace anios_tecn = 6 if e54_3_3 == 1
        replace anios_tecn = 3 if e54_3_3 == 2
        
        replace anios_prim = 6 if anios_secun > 0 & anios_prim == 0
        replace anios_prim = 6 if anios_terc > 0 & anios_prim == 0
        replace anios_secun = 6 if anios_terc > 0 & anios_secun == 0
        
        gen educ_level = 1 if (anios_secun == 0 & anios_tecn == 0)
        replace educ_level = 2 if inlist(anios_secun,1,2,3,4,5) | ///
            inlist(anios_tecn,1,2,3,4,5)
        replace educ_level = 3 if (anios_secun == 6 & !missing(anios_secun) | ///
            anios_tecn >= 6 & !missing(anios_tecn))
        replace educ_level = 4 if (anios_terc > 0 & !missing(anios_terc))

        destring numero, replace
        destring anio, replace
        destring secc, replace
        destring segm, replace
        destring estrato, replace
        
        gen nomloc = ""

        keep numero pers anio trimestre mes dpto secc segm estrato loc nomloc ccz    ///
             peso* hombre edad ytotal y_hogar* nbr_people nbr_above14 nbr_under14    ///
             pobpcoac married etnia c98_* c01_* c06_* estudiante educ_level anios_* *trabaj* ///
             lp_06 li_06 region_3 region_4 live_births*    
        save ..\temp\clean_2007, replace
end 

program clean_08
        use ../temp/raw_2008.dta, clear
        
        capture rename Dpto dpto
        capture rename Trimestre trimestre
        capture rename Estrato estrato
        capture rename PT1  pt1
        capture rename HT11 ht11
        capture rename HT3  ht3
            
        rename (nper e28     nom_locagr      pesoano e27     pt1    ht11                       ///
                f68          f88_1           f101            f89_1            f89_2            ///
                d24          d26             ht3     f102                                      ///
                e41          e42_1           e31_1   e31_2   e31_3  e31_4    e31_5_1)          ///
               (pers edad    nomloc          pesoan  hombre  ytotal  y_hogar                   ///
                trabajo_1    horas_trabajo_p horas_trabajo_s meses_trabajando anios_trabajando ///
                nbr_above14  nbr_people      nbr_under14     busca_trabajo                     ///
                live_births  live_births_nbr afro    asia    blanco indigena otro )

        gen    c98_resid_house        =    (c1!=5)
        gen    c06_mat_walls        =    (c2==1|c2==2)
        gen    c06_mat_roof        =    (c3==1|c3==2)
        gen    c06_mat_floor        =    (c4==1|c4==2)
        gen    c98_resid_owned        =    (d8_1==1|d8_1==2|d8_1==3|d8_1==4)
        gen    c98_nbr_rooms        =    d9
        gen    c98_nbr_bedrooms    =    d10
        gen    c98_b_piped_water    =    (d14_1==1)
        gen    c98_hhld_toilet        =    (d15==1)
        gen    c98_b_sewage        =    (d18_1==1)
        gen    c06_b_electr        =    (d19_1==1|d19_1==2)
        gen    c98_hhld_stove        =    (d20!=3)
        gen    c98_hhld_hot_water    =    (d22_1_1==1|d22_1_2==1|d22_1_3==1|d22_2_1==1|d22_2_2==1)
        gen    c98_hhld_refrigerat    =    (d22_1_2==1|d22_4==1)
        gen    c98_hhld_tv            =    (d22_5_1==1)
        gen    c98_hhld_vcr        =    (d22_8==1|d22_9==1)
        gen    c98_hhld_wash_mac    =    (d22_10==1)
        gen    c98_hhld_dishwasher    =    (d22_12==1)
        gen    c98_hhld_microwave    =    (d22_13==1)
        gen    c98_hhld_car        =    (d22_18_1==1)
        gen    c01_hhld_computer    =    (d22_14_1==1)
        gen    c01_hhld_internet    =    (d22_15_1==1|d22_15_2==1)
        gen    c01_hhld_phone        =    (d22_16_1==1|d22_17_1==1)
        gen    c01_hhld_cable_tv    =    (d22_7==1)
        
        gen married  = (e37==1|e40==2) if e37!=0
        clean_etnia_variable
        
        gen estudiante = (pobpcoac == 7)
        gen trabajo    = (pobpcoac == 2)
        bysort numero: egen y_hogar_alt = sum(ytotal) 
        gen horas_trabajo =  horas_trabajo_p + horas_trabajo_s
        
        gen anios_prim = (e52_2 + e52_3)
        replace anios_prim = 0 if e51 == 2
            
        gen anios_secun = (e52_4 + e52_5)
        replace anios_secun = 0 if e51 == 2        
        
        gen anios_terc = (e52_8 + e52_9 + e52_10 + e52_11)
        replace anios_terc = 0 if e51 == 2
        
        gen anios_tecn = (e52_6 + e52_7_1)
        replace anios_tecn = 0 if e51 == 2
        
        replace anios_prim = 6 if anios_secun > 0 & anios_prim == 0
        replace anios_prim = 6 if anios_terc > 0 & anios_prim == 0
        replace anios_secun = 6 if anios_terc > 0 & anios_secun == 0
        
        if anios_terc > 0  & e53_2 == 2 {
           replace anios_terc = anios_terc - 1 
        }
        
        if anios_tecn > 0 & anios_terc == 0 & e53_2 == 2 {
           replace anios_tecn = anios_tecn - 1 
        }
        
        if anios_secun > 0 & anios_tecn == 0 & anios_terc == 0 & e53_2 == 2 {
           replace anios_secun = anios_secun - 1 
        }        
        
        if anios_prim > 0 & anios_secun == 0 & anios_tecn == 0 & ///
            anios_terc == 0 & e53_2 == 2 {
           replace anios_prim = anios_prim - 1 
        }   
        
        gen educ_level = 1 if (anios_secun == 0 & anios_tecn == 0)
        replace educ_level = 2 if inlist(anios_secun,1,2,3,4,5) | ///
            inlist(anios_tecn,1,2,3,4,5)
        replace educ_level = 3 if (anios_secun == 6 & !missing(anios_secun) | ///
            anios_tecn >= 6 & !missing(anios_tecn))
        replace educ_level = 4 if (anios_terc > 0 & !missing(anios_terc))

        destring numero, replace
        destring anio, replace
        destring secc, replace
        destring segm, replace
        destring estrato, replace
        
        gen loc = ""    

        keep numero pers anio trimestre mes dpto  secc segm estrato loc nomloc ccz  ///
             peso* hombre edad ytotal y_hogar* nbr_people nbr_above14 nbr_under14    ///
             pobpcoac married etnia c98_* c01_* c06_* estudiante educ_level anios_* *trabaj* ///
             lp_06 li_06 region_3 region_4 live_births*
        save ..\temp\clean_2008, replace
end 

program clean_09_16

    forval year=2009/2016 {
        use ../temp/raw_`year'.dta, clear
        
        capture rename estratogeo09 estrato
        capture rename estratogeo estrato
        capture rename estred13 estrato
        capture rename PT1 pt1
        capture rename HT11 ht11    
        capture rename HT3 ht3
        capture rename Loc_agr_13 locagr
        capture rename Nom_loc_agr_13 nom_locagr
        capture rename POBPCOAC pobpcoac
            
        rename (nper e27    e26      locagr nom_locagr      pesoano pt1      ht11             ///
                f66         f85             f98             f88_1            f88_2            ///
                d23         d25             ht3             f99              e29_6)           ///
               (pers edad   hombre   loc    nomloc          pesoan  ytotal   y_hogar          ///
                trabajo_1   horas_trabajo_p horas_trabajo_s meses_trabajando anios_trabajando ///
                nbr_above14 nbr_people      nbr_under14     busca_trabajo    ascendencia)
        
        gen    c98_resid_house        =    (c1!=5)
        gen    c06_mat_walls        =    (c2==1|c2==2)
        gen    c06_mat_roof        =    (c3==1|c3==2)
        gen    c06_mat_floor        =    (c4==1|c4==2)
        gen    c98_resid_owned        =    (d8_1==1|d8_1==2|d8_1==3|d8_1==4)
        gen    c98_nbr_rooms        =    d9
        gen    c98_nbr_bedrooms    =    d10
        gen    c98_b_piped_water    =    (d12==1)
        gen    c98_hhld_toilet        =    (d13==1)
        gen    c98_b_sewage        =    (d16==1)
        gen    c06_b_electr        =    (d18==1)
        gen    c98_hhld_stove        =    (d19!=3)
        gen    c98_hhld_hot_water    =    (d21_1==1|d21_2==1)
        gen    c98_hhld_refrigerat    =    (d21_3==1)
        gen    c98_hhld_tv            =    (d21_4==1|d21_5==1)
        gen    c98_hhld_vcr        =    (d21_8==1|d21_9==1)
        gen    c98_hhld_wash_mac    =    (d21_10==1)
        gen    c98_hhld_dishwasher    =    (d21_12==1)
        gen    c98_hhld_microwave    =    (d21_13==1)
        gen    c98_hhld_car        =    (d21_18==1)
        gen    c01_hhld_computer    =    (d21_15==1)
        gen    c01_hhld_internet    =    (d21_16==1)
        gen    c01_hhld_phone        =    (d21_17    ==1)
        gen    c01_hhld_cable_tv    =    (d21_7==1)
        
        capture gen trimestre = 1 if inlist(mes, 1, 2, 3)
        capture replace trimestre = 2 if inlist(mes, 4, 5, 6)
        capture replace trimestre = 3 if inlist(mes, 7, 8, 9)
        capture replace trimestre = 4 if inlist(mes, 10, 11, 12)
        capture gen pesosem = .
        capture gen pesotri = .

        gen married  = (e33==1|e35!=0|e36==3) if e33!=0
        gen etnia = ascendencia
        replace etnia=0 if ascendencia==5
        
        gen estudiante = (pobpcoac == 7)
        gen trabajo    = (pobpcoac == 2)
        bysort numero: egen y_hogar_alt = sum(ytotal) 
        gen horas_trabajo =  horas_trabajo_p + horas_trabajo_s

        if "`year'" <= "2010" {
            gen anios_prim = (e51_2 + e51_3)
            replace anios_prim = 0 if e50 == 2
                
            gen anios_secun = (e51_4 + e51_5)
            replace anios_secun = 0 if e50 == 2        
            
            gen anios_terc = (e51_8 + e51_9 + e51_10 + e51_11)
            replace anios_terc = 0 if e50 == 2
            
            gen anios_tecn = (e51_6 + e51_7)
            replace anios_tecn = 0 if e50 == 2
            
            replace anios_prim = 6 if anios_secun > 0 & anios_prim == 0
            replace anios_prim = 6 if anios_terc > 0 & anios_prim == 0
            replace anios_secun = 6 if anios_terc > 0 & anios_secun == 0
            
            if anios_terc > 0  & e53 == 2 {
               replace anios_terc = anios_terc - 1 
            }
            
            if anios_tecn > 0 & anios_terc == 0 & e53 == 2 {
               replace anios_tecn = anios_tecn - 1 
            }
            
            if anios_secun > 0 & anios_tecn == 0 & anios_terc == 0 & e53 == 2 {
               replace anios_secun = anios_secun - 1 
            }        
            
            if anios_prim > 0 & anios_secun == 0 & anios_tecn == 0 & ///
                anios_terc == 0 & e53 == 2 {
               replace anios_prim = anios_prim - 1 
            }   
            
            gen educ_level = 1 if (anios_secun == 0 & anios_tecn == 0)
            replace educ_level = 2 if inlist(anios_secun,1,2,3,4,5) | ///
                inlist(anios_tecn,1,2,3,4,5)
            replace educ_level = 3 if (anios_secun == 6 & !missing(anios_secun) | ///
                anios_tecn >= 6 & !missing(anios_tecn))
            replace educ_level = 4 if (anios_terc > 0 & !missing(anios_terc))

            gen educ_ini = (e54 == 1)

            gen live_births     = .
            gen live_births_nbr = .
            }
        else {
            gen anios_prim = (e51_2 + e51_3)
            replace anios_prim = 0 if e49 == 2
                
            gen anios_secun = (e51_4 + e51_5)
            replace anios_secun = 0 if e49 == 2     
            
            gen anios_terc = (e51_8 + e51_9 + e51_10 + e51_11)
            replace anios_terc = 0 if e49 == 2
            
            gen anios_tecn = (e51_6 + e51_7)
            replace anios_tecn = 0 if e49 == 2
            
            replace anios_prim = 6 if anios_secun > 0 & anios_prim == 0
            replace anios_prim = 6 if anios_terc > 0 & anios_prim == 0
            replace anios_secun = 6 if anios_terc > 0 & anios_secun == 0
            
            gen educ_level = 1 if (anios_secun == 0 & anios_tecn == 0)
            replace educ_level = 2 if inlist(anios_secun,1,2,3,4,5) | ///
                inlist(anios_tecn,1,2,3,4,5)
            replace educ_level = 3 if (anios_secun == 6 & !missing(anios_secun) | ///
                anios_tecn >= 6 & !missing(anios_tecn))
            replace educ_level = 4 if (anios_terc > 0 & !missing(anios_terc))

            gen educ_ini = (e193 == 1) if edad <= 3 
            gen live_births     = e185
            gen live_births_nbr = e186_1 + e186_2 + e186_3 + e186_4 
        }
        
        destring numero, replace
        destring anio, replace
        destring secc, replace
        destring segm, replace
        destring estrato, replace
        
        keep numero pers anio trimestre mes dpto secc segm estrato loc nomloc ccz*  ///
             peso* hombre edad ytotal y_hogar* nbr_people nbr_above14 nbr_under14    ///
             pobpcoac married etnia c98_* c01_* c06_* estudiante educ_level anios_* *trabaj* ///
             educ_ini lp_06 li_06 region_3 region_4 live_births*
        save ..\temp\clean_`year', replace
        }
end

main_clean_raw
