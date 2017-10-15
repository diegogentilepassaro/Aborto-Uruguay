clear all
set more off

program main_assign_treatment
	assign_treatment
end

program assign_treatment
   	use ..\temp\clean_loc_1998_2016_pers.dta, clear 
    
	gen rivera_city = (loc == "13020" & dpto == 13)
	gen salto_city = (loc == "15020" & dpto == 15)
	
	gen anio_qtr = yq(anio, trimestre)
	format anio_qtr %tq
	drop anio trimestre
	
	gen post_rivera = (anio_qtr >= tq(2010q2)) /* apertura de clinica en Rivera */
	gen post_salto = (anio_qtr >= tq(2013q1)) /* implementacion de la ley IVE */
	
	/* Para empezar metamos a Paysandu de control para Salto y para Rivera
	despues hacemos algo con synthetic control o algo asi, que ya tengo el 
	codigo del proyecto de Katrina */
	
	gen control_paysandu = (loc == "11020" & dpto == 11)
	
   	save ..\base\ech_final_98_2016.dta, replace 
end

main_assign_treatment
