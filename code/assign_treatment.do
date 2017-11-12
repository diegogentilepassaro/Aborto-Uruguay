clear all
set more off

program main_assign_treatment
    assign_treatment
end

program assign_treatment
    use ..\base\clean_loc_1998_2016.dta, clear 
    
    gen treatment_rivera = (loc_code == 1313020 & hombre == 0)
    gen treatment_salto  = (loc_code == 1515020 & hombre == 0)

	gen placebo_rivera   = (loc_code == 1313020 & hombre == 1)
    gen placebo_salto    = (loc_code == 1515020 & hombre == 1)
	
    gen control_paysandu = (loc_code == 1111020 & hombre == 0)
    gen control_artigas  = (loc_code == 202020  & hombre == 0)

	* for experimenting with triple diff
	gen fertile_age = (inrange(edad, 14, 45)) if inrange(edad,14,60)
	gen female = (hombre==0)
	
	* Design 1: income_gender
	gen mvd_poor_male       = (loc_code == 101010 & hombre == 1 & pobre == 1 & inrange(edad, 14, 60))
	gen mvd_poor_female     = (loc_code == 101010 & hombre == 0 & pobre == 1 & inrange(edad, 14, 60))
	gen mvd_non_poor_male   = (loc_code == 101010 & hombre == 1 & pobre == 0 & inrange(edad, 14, 60))
	gen mvd_non_poor_female = (loc_code == 101010 & hombre == 0 & pobre == 0 & inrange(edad, 14, 60))

	* Design 2: income_fertility (only women)
	gen mvd_poor_fertile       = (loc_code == 101010 & pobre == 1 & fertile_age == 1 & hombre == 0)
	gen mvd_poor_infertile     = (loc_code == 101010 & pobre == 1 & fertile_age == 0 & hombre == 0)
	gen mvd_non_poor_fertile   = (loc_code == 101010 & pobre == 0 & fertile_age == 1 & hombre == 0)
	gen mvd_non_poor_infertile = (loc_code == 101010 & pobre == 0 & fertile_age == 0 & hombre == 0)
  	
	* Design 3: gender_fertility
	gen mvd_female_fertile    = (loc_code == 101010 & hombre == 0 & fertile_age == 1)
	gen mvd_female_infertile  = (loc_code == 101010 & hombre == 0 & fertile_age == 0)
	gen mvd_male_fertile      = (loc_code == 101010 & hombre == 1 & fertile_age == 1)
	gen mvd_male_infertile    = (loc_code == 101010 & hombre == 1 & fertile_age == 0)     
    
    save ..\base\ech_final_98_2016.dta, replace 
end

main_assign_treatment
