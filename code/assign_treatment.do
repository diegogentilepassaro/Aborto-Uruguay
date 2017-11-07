clear all
set more off

program main_assign_treatment
    assign_treatment
end

program assign_treatment
    use ..\temp\clean_loc_1998_2016.dta, clear 
    
    gen treatment_rivera    = (loc_code == 1313020 & hombre == 0)
    gen treatment_salto     = (loc_code == 1515020 & hombre == 0)

	gen placebo_rivera    = (loc_code == 1313020 & hombre == 1)
    gen placebo_salto     = (loc_code == 1515020 & hombre == 1)
	
    gen control_paysandu = (loc_code == 1111020 & hombre == 0)
    gen control_artigas   = (loc_code == 202020 & hombre == 0)

	gen semestre = 1 if inlist(trimestre, 1, 2)
	replace semestre = 2 if inlist(trimestre, 3, 4)
	gen anio_sem = yh(anio, semestre)
	format anio_sem %th
	
    gen    anio_qtr = yq(anio, trimestre)
    format anio_qtr %tq
	
	* for experimenting with triple diff
	
	* design 1
	gen mvd_poor_male = (loc_code == 101010 & hombre == 1 & pobre == 1)
	gen mvd_poor_female = (loc_code == 101010 & hombre == 0 & pobre == 1)
	gen mvd_non_poor_male = (loc_code == 101010 & hombre == 1 & pobre == 0)
	gen mvd_non_poor_female = (loc_code == 101010 & hombre == 0 & pobre == 0)

	* design 2
	gen mvd_poor_fertile = (loc_code == 101010 & pobre == 1 & inrange(edad, 14, 40))
	gen mvd_poor_infertile = (loc_code == 101010 & pobre == 1 & inrange(edad, 40, 60))
	gen mvd_non_poor_fertile = (loc_code == 101010 & pobre == 0 & inrange(edad, 14, 40))
	gen mvd_non_poor_infertile = (loc_code == 101010 & pobre == 0 & inrange(edad, 40, 60))    
    
    save ..\base\ech_final_98_2016.dta, replace 
end

main_assign_treatment
