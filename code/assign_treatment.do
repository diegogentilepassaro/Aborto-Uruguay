clear all
set more off

program main_assign_treatment
	assign_treatment
end

program assign_treatment
   	use ..\temp\clean_loc_1998_2016.dta, clear 
    
	gen treatment_rivera    = (loc == "13020" & dpto == 13 & hombre == 0)
	gen treatment_salto     = (loc == "15020" & dpto == 15 & hombre == 0)
	gen treatment_mvd_city  = (loc == "01010" & dpto == 1  & hombre == 0 & inrange(edad,30,40) ///
	                           & inlist(ccz, 1 , 2, 3, 4, 5, 6, 7, 8, 15, 16))
	gen treatment_mvd_perif = (((loc == "01010" & dpto == 1 & inlist(ccz, 9, 10, 11, 12, 13, 14, 17, 18)) | ///
	    (loc == "30020" & dpto == 3) | (loc == "30020" & dpto == 16)) & hombre == 0)
	
	/* Para empezar metamos a Paysandu de control para Salto y para Rivera
	despues hacemos algo con synthetic control o algo asi, que ya tengo el 
	codigo del proyecto de Katrina */
	
	gen control_paysandu = (loc == "11020" & dpto == 11 & hombre == 0)
	gen control_rivera   = (loc == "02020" & dpto == 2  & hombre == 0)
	gen control_mvd_city = (loc == "01010" & dpto == 1  & hombre == 0 & inrange(edad,45,55) ///
	                         & inlist(ccz, 1 , 2, 3, 4, 5, 6, 7, 8, 15, 16))
	gen control_mvd_perif = (((loc == "01010" & dpto == 1 & inlist(ccz, 9, 10, 11, 12, 13, 14, 17, 18)) | ///
	    (loc == "30020" & dpto == 3) | (loc == "30020" & dpto == 16)) & hombre == 1)
		
	gen    anio_qtr = yq(anio, trimestre)
	format anio_qtr %tq
	
	gen post_is_chpr = (anio_qtr >= tq(2002q1))
	gen post_n369    = (anio_qtr >= tq(2004q4))
	gen post_rivera  = (anio_qtr >= tq(2010q2)) /* apertura de clinica en Rivera */
	gen post_ive     = (anio_qtr >= tq(2012q4)) /* implementacion de la ley IVE */
	
   	save ..\base\ech_final_98_2016.dta, replace 
end

main_assign_treatment
