clear all
set more off

program main_assign_treatment
    assign_treatment
end

program assign_treatment
    use ..\temp\clean_loc_1998_2016.dta, clear 
    
    gen treatment_rivera    = (loc_code == 1313020 & hombre == 0)
    gen treatment_salto     = (loc_code == 1515020 & hombre == 0)
    gen treatment_mvd       = (loc_code == 101010 & hombre == 0)
	
	/*gen treatment_mvd_city  = (hombre == 0 & inlist(loc_code, 1 , 2, 3, 4, 5, 6, 7, 8, 15, 16))
    gen treatment_mvd_perif = (((inlist(loc_code, 9, 10, 11, 12, 13, 14, 17, 18)) | ///
        (loc_code == 330020) | (loc_code == 1630020)) & hombre == 0)*/
    
    /* Para empezar metamos a Paysandu de control para Salto y para Rivera
    despues hacemos algo con synthetic control o algo asi, que ya tengo el 
    codigo del proyecto de Katrina 
	    gen control_mvd_city = (loc_code == 101010 & hombre == 0 & inlist(loc_code, 1 , 2, 3, 4, 5, 6, 7, 8, 15, 16))
    gen control_mvd_perif = (((loc_code == 101010& inlist(loc_code, 9, 10, 11, 12, 13, 14, 17, 18)) | ///
        (loc_code == 330020) | (loc_code == 1630020)) & hombre == 1)*/
    
    gen control_paysandu = (loc_code == 1111020 & hombre == 0)
    gen control_artigas   = (loc_code == 202020 & hombre == 0)
    gen control_mvd = (loc_code == 101010 & hombre == 1)

	gen semestre = 1 if inlist(trimestre, 1, 2)
	replace semestre = 2 if inlist(trimestre, 3, 4)
	gen anio_sem = yh(anio, semestre)
	format anio_sem %th
	
    gen    anio_qtr = yq(anio, trimestre)
    format anio_qtr %tq
    
    save ..\base\ech_final_98_2016.dta, replace 
end

main_assign_treatment
