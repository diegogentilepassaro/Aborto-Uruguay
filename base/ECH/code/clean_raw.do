clear all
set more off
adopath + ../../../library/stata/gslab_misc/ado

program main_clean_raw
    clean_01_05 
    clean_06
    clean_07
    clean_08
    clean_09_15
end

program clean_01_05
    * Note: there is no nomdepto for 2005: check running table nomdpto anio
    
    foreach year in 2001 2002 2003 2004 2005 {
        foreach t in p h {
            import excel using "..\..\..\raw/`year'/`t'`year'.xls", clear first
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
                f17_1            f17_2           f23 ///
                d14              d16             ht3) ///               
               (numero     pers  loc             nomloc ///
                hombre     edad  ytotal          y_hogar ///
                horas_trabajo_p  horas_trabajo_s busca_trabajo ///
                nbr_above14      nbr_people      nbr_under14)

        gen    piped_water        =    (d6==1)
        gen    toilet        =    (d7==1)
        gen    sewage             =    (d8==1)
        gen    stove         =    (d9!=5)        
        gen    hot_water     =    (d10_1==1|d10_2==1)
        gen    refrigerat    =    (d10_3==1)
        gen    tv            =    (d10_4==1)
        gen    car           =    (d10_12==1)
        gen    computer      =    (d10_10==1)
        gen    internet      =    (d10_11==1)
        
        if `year' == 2001 | `year' == 2002 | `year' == 2003 {
            * no insurance
            gen health_insurance = 0
            
            * public
            replace health_insurance = 1 if e8_1 == 1
            * military or police
            replace health_insurance = 2 if e8_2 == 1
            * municipal
            replace health_insurance = 3 if e8_3 == 1
            * IAMC
            replace health_insurance = 4 if e5 == 1
            * other
            replace health_insurance = 5 if e8_4_1 == 1
        }
        else {
            * no insurance
            gen health_insurance = 0
            
            * public
            replace health_insurance = 1 if e5_1 == 1
            * military or police
            replace health_insurance = 2 if e5_2 == 1
            * municipal
            replace health_insurance = 3 if e5_3 == 1
            * IAMC
            replace health_insurance = 4 if e5_5 == 1
            * other
            replace health_insurance = 5 if (e5_4 == 1 | e5_6_1 == 1)
        }

        gen public_health = (health_insurance == 1)

        gen blanco = .

        capture gen     trimestre = 1 if inlist(mes, 1, 2, 3)
        capture replace trimestre = 2 if inlist(mes, 4, 5, 6)
        capture replace trimestre = 3 if inlist(mes, 7, 8, 9)
        capture replace trimestre = 4 if inlist(mes, 10, 11, 12)
        
        gen married = (e4==1|e4==2)

        gen estudiante = (pobpcoac==7)
        gen trabajo    = (pobpcoac==2)
        gen horas_trabajo =  horas_trabajo_p + horas_trabajo_s

        foreach var in hombre busca_trabajo {
            replace `var' = 0 if `var' == 2
        }

        keep numero pers anio trimestre mes dpto secc segm estrato loc nomloc ccz*  ///
             peso* hombre edad ytotal y_hogar nbr_people nbr_above14 nbr_under14    ///
             married estudiante trabajo horas_trabajo blanco health_insurance ///
             public_health piped_water toilet sewage stove hot_water refrigerat tv /// 
             car computer internet
        
        save_data ..\temp\clean_`year'.dta, key(anio pers numero) replace
    }
    * Estudiante: {1=si,2=no} --> but estudiante=0 en 3.5%, would it be no response?
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

        rename (nper            locagr            nom_locagr        e27   ///
                e26             pesoano           pt1               ht11             ///
                f62             f81               f93               d25   ///
                ht3             f102              e30_1             e30_2  ///
                e30_3             e30_4     e30_5_2)        ///
               (pers            loc               nomloc            edad  ///
                hombre          pesoan            ytotal            y_hogar                ///
                horas_trabajo_p horas_trabajo_s   nbr_above14       nbr_people      ///
                nbr_under14     busca_trabajo     afro              asia     ///
                blanco            indigena          otro)

        gen    piped_water        =    (d13==1)
        gen    toilet        =    (d14==1)
        gen    sewage             =    (d17==1)
        gen    stove              =    (d19!=3)
        gen    hot_water          =    (d21_1_1==1|d21_1_2==1|d21_1_3==1|d21_2_1==1|d21_2_2==1)
        gen    refrigerat         =    (d21_3==1|d21_4==1)
        gen    tv                 =    (d21_5_1==1)
        gen    car                =    (d21_18_1==1)
        gen    computer           =    (d21_14_1==1)
        gen    internet           =    (d21_15==1)

        * no insurance
        gen health_insurance = 0    
        * public
        replace health_insurance = 1 if (e42_1 == 1 |  e42_2 == 1)
        * military or police
        replace health_insurance = 2 if (e42_3 == 1 | e42_4 == 1)
        * municipal
        replace health_insurance = 3 if e42_5 == 1
        * IAMC
        replace health_insurance = 4 if e42_7 == 1
        * other
        replace health_insurance = 5 if (e42_6 == 1 | e42_8 == 1 | ///
            e42_9 == 1 | e42_10 == 1 | e42_11_1 == 1)

        gen public_health = (health_insurance == 1)
        
        gen married  = (e34==1|e37==2) if e34!=0

        replace blanco = 0 if blanco != 1
        
        gen estudiante = (pobpcoac == 7)
        gen trabajo    = (pobpcoac == 2)
        gen horas_trabajo =  horas_trabajo_p + horas_trabajo_s

        destring anio, replace
        destring secc, replace
        destring segm, replace
        destring estrato, replace
        
        foreach var in hombre busca_trabajo {
            replace `var' = 0 if `var' == 2
        }

        keep numero pers anio trimestre mes dpto secc segm estrato loc nomloc ccz*  ///
             peso* hombre edad ytotal y_hogar nbr_people nbr_above14 nbr_under14    ///
             married estudiante trabajo horas_trabajo lp_06 blanco health_insurance ///
             public_health piped_water toilet sewage stove hot_water refrigerat tv /// 
             car computer internet
		
        save_data ..\temp\clean_2006.dta, key(anio pers numero) replace   
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
                    
        rename (nper             loc_agr          pesoano         e27  ///
                e28              pt1              ht11            f88  ///
                f101             d24              d26             ht3  ///
                f102             e31_1            e31_2           e31_3  ///
                e31_4            e31_5_1)    ///
               (pers             loc              pesoan          hombre   ///
                edad             ytotal           y_hogar         horas_trabajo_p  ///
                horas_trabajo_s  nbr_above14     nbr_people       nbr_under14      ///
                busca_trabajo    afro            asia             blanco           ///
                indigena         otro)

        gen    piped_water    =    (d14_1==1)
        gen    toilet         =    (d15==1)
        gen    sewage         =    (d18_1==1)
        gen    stove          =    (d20!=3)
        gen    hot_water      =    (d22_1_1==1|d22_1_2==1|d22_1_3==1|d22_2_1==1|d22_2_2==1)
        gen    refrigerat     =    (d22_1_2==1|d22_4==1)
        gen    tv             =    (d22_5_1==1)
        gen    car            =    (d22_18_1==1)
        gen    computer       =    (d22_14_1==1)
        gen    internet       =    (d22_15_1==1|d22_15_2==1)

        * no insurance
        gen health_insurance = 0    
        * public
        replace health_insurance = 1 if (e43_1 == 1 |  e43_2 == 1)
        * military or police
        replace health_insurance = 2 if (e43_3 == 1 | e43_4 == 1)
        * municipal
        replace health_insurance = 3 if e43_5 == 1
        * IAMC
        replace health_insurance = 4 if e43_7 == 1
        * other
        replace health_insurance = 5 if (e43_6 == 1 | e43_8 == 1 | ///
            e43_9 == 1 | e43_10 == 1 | e43_11_1 == 1)

        gen public_health = (health_insurance == 1)
        
        gen married  = (e37==1|e40==2) if e37!=0
        
        replace blanco = 0 if blanco != 1
        
        gen estudiante = (pobpcoac == 7)
        gen trabajo    = (pobpcoac == 2)
        gen horas_trabajo =  horas_trabajo_p + horas_trabajo_s

        destring numero, replace
        destring anio, replace
        destring secc, replace
        destring segm, replace
        destring estrato, replace
        
        gen nomloc = ""
        
        foreach var in hombre busca_trabajo {
            replace `var' = 0 if `var' == 2
        }

        keep numero pers anio trimestre mes dpto secc segm estrato loc nomloc ccz*  ///
             peso* hombre edad ytotal y_hogar nbr_people nbr_above14 nbr_under14    ///
             married estudiante trabajo horas_trabajo lp_06 blanco health_insurance ///
             public_health piped_water toilet sewage stove hot_water refrigerat tv /// 
             car computer internet
		
        save_data ..\temp\clean_2007.dta, key(anio pers numero) replace
end 

program clean_08
        use ../temp/raw_2008.dta, clear
        
        capture rename Dpto dpto
        capture rename Trimestre trimestre
        capture rename Estrato estrato
        capture rename PT1  pt1
        capture rename HT11 ht11
        capture rename HT3  ht3
            
        rename (nper            e28             nom_locagr      pesoano  ///    
                e27             pt1             ht11            f88_1    ///
                f101            d24             d26             ht3      ///
                f102            e31_1           e31_2           e31_3    ///
                e31_4           e31_5_1)          ///
               (pers            edad            nomloc          pesoan   ///
                hombre          ytotal          y_hogar         horas_trabajo_p ///
                horas_trabajo_s nbr_above14     nbr_people      nbr_under14  ///
                busca_trabajo   afro            asia            blanco       ///
                indigena        otro )

        gen    piped_water    =    (d14_1==1)
        gen    toilet         =    (d15==1)
        gen    sewage         =    (d18_1==1)
        gen    stove          =    (d20!=3)
        gen    hot_water      =    (d22_1_1==1|d22_1_2==1|d22_1_3==1|d22_2_1==1|d22_2_2==1)
        gen    refrigerat     =    (d22_1_2==1|d22_4==1)
        gen    tv             =    (d22_5_1==1)
        gen    car            =    (d22_18_1==1)
        gen    computer       =    (d22_14_1==1)
        gen    internet       =    (d22_15_1==1|d22_15_2==1)
        
        * no insurance
        gen health_insurance = 0    
        * public
        replace health_insurance = 1 if (e43_1 == 1 |  e43_2 == 1)
        * military or police
        replace health_insurance = 2 if (e43_3 == 1 | e43_4 == 1)
        * municipal
        replace health_insurance = 3 if e43_5 == 1
        * IAMC
        replace health_insurance = 4 if e43_7 == 1
        * other
        replace health_insurance = 5 if (e43_6 == 1 | e43_8 == 1 | ///
            e43_9 == 1 | e43_10 == 1 | e43_11_1 == 1)
        
        gen public_health = (health_insurance == 1)

        gen married  = (e37==1|e40==2) if e37!=0
        replace blanco = 0 if blanco != 1
        
        gen estudiante = (pobpcoac == 7)
        gen trabajo    = (pobpcoac == 2)
        gen horas_trabajo =  horas_trabajo_p + horas_trabajo_s
        
        destring numero, replace
        destring anio, replace
        destring secc, replace
        destring segm, replace
        destring estrato, replace
        
        gen loc = ""    
        
        foreach var in hombre busca_trabajo {
            replace `var' = 0 if `var' == 2
        }

        keep numero pers anio trimestre mes dpto secc segm estrato loc nomloc ccz*  ///
             peso* hombre edad ytotal y_hogar nbr_people nbr_above14 nbr_under14    ///
             married estudiante trabajo horas_trabajo lp_06 blanco health_insurance ///
             public_health piped_water toilet sewage stove hot_water refrigerat tv /// 
             car computer internet

		save_data ..\temp\clean_2008.dta, key(anio pers numero) replace
end 

program clean_09_15

    forval year=2009/2015{
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
            
        rename (nper            e27             e26          locagr    ///
                nom_locagr      pesoano         pt1          ht11             ///
                f85             f98             d23          d25       ///
                ht3             f99             e29_6)      ///
               (pers            edad            hombre       loc    ///
                nomloc          pesoan          ytotal       y_hogar          ///
                horas_trabajo_p horas_trabajo_s nbr_above14  nbr_people  ///
                nbr_under14     busca_trabajo    ascendencia)
        

        gen    piped_water    =    (d12==1)
        gen    toilet         =    (d13==1)
        gen    sewage         =    (d16==1)
        gen    stove          =    (d19!=3)
        gen    hot_water      =    (d21_1==1|d21_2==1)
        gen    refrigerat     =    (d21_3==1)
        gen    tv             =    (d21_4==1|d21_5==1)
        gen    car            =    (d21_18==1)
        gen    computer       =    (d21_15==1)
        gen    internet       =    (d21_16==1)
        
        * no insurance
        gen health_insurance = 0    
        * public
        replace health_insurance = 1 if e45_1 == 1
        * military or police
        replace health_insurance = 2 if e45_4 == 1
        * municipal
        replace health_insurance = 3 if e45_6 == 1
        * IAMC
        replace health_insurance = 4 if e45_2 == 1
        * other
        replace health_insurance = 5 if (e45_3 == 1 | e45_5 == 1 | ///
            e45_7 == 1)

        gen public_health = (health_insurance == 1)
            
        capture gen trimestre = 1 if inlist(mes, 1, 2, 3)
        capture replace trimestre = 2 if inlist(mes, 4, 5, 6)
        capture replace trimestre = 3 if inlist(mes, 7, 8, 9)
        capture replace trimestre = 4 if inlist(mes, 10, 11, 12)
        capture gen pesosem = .
        capture gen pesotri = .

        gen married  = (e33==1|e35!=0|e36==3) if e33!=0
        gen blanco = (ascendencia == 3)
        
        gen estudiante = (pobpcoac == 7)
        gen trabajo    = (pobpcoac == 2)
        gen horas_trabajo =  horas_trabajo_p + horas_trabajo_s
        
        destring numero, replace
        destring anio, replace
        destring secc, replace
        destring segm, replace
        destring estrato, replace

        foreach var in hombre busca_trabajo {
            replace `var' = 0 if `var' == 2
        }
                
        keep numero pers anio trimestre mes dpto secc segm estrato loc nomloc ccz*  ///
             peso* hombre edad ytotal y_hogar nbr_people nbr_above14 nbr_under14    ///
             married estudiante trabajo horas_trabajo lp_06 blanco health_insurance ///
             public_health piped_water toilet sewage stove hot_water refrigerat tv /// 
             car computer internet
        
        save_data ..\temp\clean_`year'.dta, key(anio pers numero) replace
        }
end

main_clean_raw
