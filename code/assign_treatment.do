clear all
set more off

program main_assign_treatment
    assign_treatment
end

program assign_treatment
    use ..\base\clean_loc_1998_2016.dta, clear 

	* for experimenting with triple diff
	gen fertile_age = (inrange(edad, 16, 45)) if inrange(edad,16,60)
	gen female = (hombre==0)  if !mi(hombre)
	gen single = (married==0) if !mi(married)
	
    /*gen treatment_rivera = (loc_code == 1313020 & hombre == 0)
    gen treatment_salto  = (loc_code == 1515020 & hombre == 0)

	gen placebo_rivera   = (loc_code == 1313020 & hombre == 1)
    gen placebo_salto    = (loc_code == 1515020 & hombre == 1)
	
    gen control_rivera  = (loc_code == 202020  & hombre == 0)
    gen control_salto   = (loc_code == 1111020 & hombre == 0)*/

	gen treatment_mvd_gender  = (dpto == 1 & hombre == 0)
	gen treatment_mvd_poor    = (dpto == 1 & hombre == 0 & pobre == 1)
	gen treatment_mvd_fertile = (dpto == 1 & hombre == 0 & fertile_age == 1)
	gen treatment_mvd_educ    = (dpto == 1 & hombre == 0 & educ_HS_or_more == 0)
	gen treatment_mvd_married    = (dpto == 1 & hombre == 0 & married == 0)
	gen treatment_mvd_student    = (dpto == 1 & hombre == 0 & estudiante == 1)
	
    gen treatment_rivera = (dpto == 13 & hombre == 0)
    gen treatment_salto  = (dpto == 15 & hombre == 0)

	gen placebo_rivera   = (dpto == 13 & hombre == 1)
    gen placebo_salto    = (dpto == 15 & hombre == 1)

	gen control_mvd_gender  = (dpto == 1 & hombre == 1)
	gen control_mvd_poor    = (dpto == 1 & hombre == 0 & pobre == 0)
	gen control_mvd_fertile = (dpto == 1 & hombre == 0 & fertile_age == 0)
	gen control_mvd_educ    = (dpto == 1 & hombre == 0 & educ_HS_or_more == 1)
    gen control_mvd_married = (dpto == 1 & hombre == 0 & married == 1)
	gen control_mvd_student    = (dpto == 1 & hombre == 0 & estudiante == 0)

    gen control_rivera   = (dpto == 4 & hombre == 0)
    gen control_salto    = (dpto == 11  & hombre == 0)
	
	* Design 1: income_gender
	gen mvd_poor_male       = (loc_code == 101010 & hombre == 1 & pobre == 1 & inrange(edad, 16, 60))
	gen mvd_poor_female     = (loc_code == 101010 & hombre == 0 & pobre == 1 & inrange(edad, 16, 60))
	gen mvd_non_poor_male   = (loc_code == 101010 & hombre == 1 & pobre == 0 & inrange(edad, 16, 60))
	gen mvd_non_poor_female = (loc_code == 101010 & hombre == 0 & pobre == 0 & inrange(edad, 16, 60))

	/** Design 2: income_fertility (only women)
	gen mvd_poor_fertile       = (loc_code == 101010 & pobre == 1 & fertile_age == 1 & hombre == 0)
	gen mvd_poor_infertile     = (loc_code == 101010 & pobre == 1 & fertile_age == 0 & hombre == 0)
	gen mvd_non_poor_fertile   = (loc_code == 101010 & pobre == 0 & fertile_age == 1 & hombre == 0)
	gen mvd_non_poor_infertile = (loc_code == 101010 & pobre == 0 & fertile_age == 0 & hombre == 0)
  	
	* Design 3: gender_fertility
	gen mvd_female_fertile    = (loc_code == 101010 & hombre == 0 & fertile_age == 1)
	gen mvd_female_infertile  = (loc_code == 101010 & hombre == 0 & fertile_age == 0)
	gen mvd_male_fertile      = (loc_code == 101010 & hombre == 1 & fertile_age == 1)
	gen mvd_male_infertile    = (loc_code == 101010 & hombre == 1 & fertile_age == 0)     
    */

	* Design 2: income_married
	gen mvd_poor_married       = (loc_code == 101010 & hombre == 0 & pobre == 1 & married == 1)
	gen mvd_poor_single        = (loc_code == 101010 & hombre == 0 & pobre == 1 & married == 0)
	gen mvd_non_poor_married   = (loc_code == 101010 & hombre == 0 & pobre == 0 & married == 1)
	gen mvd_non_poor_single    = (loc_code == 101010 & hombre == 0 & pobre == 0 & married == 0)

	* Design 2: income_married
	gen mvd_female_married       = (loc_code == 101010 & hombre == 0 & married == 1)
	gen mvd_female_single        = (loc_code == 101010 & hombre == 0 & married == 0)
	gen mvd_male_married   = (loc_code == 101010 & hombre == 1 & married == 1)
	gen mvd_male_single    = (loc_code == 101010 & hombre == 1 & married == 0)
	
    save ..\base\ech_final_98_2016.dta, replace 
end

main_assign_treatment
