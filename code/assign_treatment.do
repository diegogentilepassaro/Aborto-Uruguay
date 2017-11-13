clear all
set more off

program main_assign_treatment
    assign_treatment
end

program assign_treatment
    use ..\base\clean_loc_1998_2016.dta, clear 

	* Variables for the triple diff
	gen fertile_age = (inrange(edad, 16, 45)) if inrange(edad,16,60)
	gen female      = (hombre==0)             if !mi(hombre)
	gen single      = (married==0)            if !mi(married)
	gen lowed       = (educ_level==1)         if !mi(educ_level)
	
	* Diff in Diff Rivera y Salto
	
	gen treatment_rivera = (loc_code == 1313020 & hombre == 0)
    gen treatment_salto  = (loc_code == 1515020 & hombre == 0)

	gen placebo_rivera   = (loc_code == 1313020 & hombre == 1)
    gen placebo_salto    = (loc_code == 1515020 & hombre == 1)
	
    gen control_rivera  = ((loc_code == 431050 | loc_code == 202020) & hombre == 0)
    gen control_salto   = ((loc_code == 1111020 |loc_code ==1212020) & hombre == 0)

	*rio branco 431050
	*artigas    202020
	
	*paysandu 1111020
	*fray bentos 1212020
	
	/*gen treatment_rivera = (dpto == 13 & hombre == 0)
    gen treatment_salto  = (dpto == 15 & hombre == 0)

	gen placebo_rivera   = (dpto == 13 & hombre == 1)
    gen placebo_salto    = (dpto == 15 & hombre == 1)
	
    gen control_rivera   = ((dpto == 2 | dpto == 4 )& hombre == 0)
    gen control_salto    = (dpto == 11  & hombre == 0)*/

	* Diff in Diff Montevideo
	gen treatment_mvd_gender  = (dpto == 1 & hombre == 0)
	gen treatment_mvd_poor    = (dpto == 1 & hombre == 0 & pobre == 1)
	gen treatment_mvd_fertile = (dpto == 1 & hombre == 0 & fertile_age == 1)
	gen treatment_mvd_educ    = (dpto == 1 & hombre == 0 & educ_HS_or_more == 0)
	gen treatment_mvd_married    = (dpto == 1 & hombre == 0 & married == 0)
	gen treatment_mvd_student    = (dpto == 1 & hombre == 0 & estudiante == 1)

	gen control_mvd_gender  = (dpto == 1 & hombre == 1)
	gen control_mvd_poor    = (dpto == 1 & hombre == 0 & pobre == 0)
	gen control_mvd_fertile = (dpto == 1 & hombre == 0 & fertile_age == 0)
	gen control_mvd_educ    = (dpto == 1 & hombre == 0 & educ_HS_or_more == 1)
    gen control_mvd_married = (dpto == 1 & hombre == 0 & married == 1)
	gen control_mvd_student    = (dpto == 1 & hombre == 0 & estudiante == 0)
	
	* Triple Diff
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
	
	* Design: female_poor
	gen mvd_female_poor       = (loc_code == 101010 & female == 1 & pobre == 1)
	gen mvd_female_rich       = (loc_code == 101010 & female == 1 & pobre == 0)
	gen mvd_male_poor         = (loc_code == 101010 & female == 0 & pobre == 1)
	gen mvd_male_rich         = (loc_code == 101010 & female == 0 & pobre == 0)
	
	* Design: female_single
	gen mvd_female_single     = (loc_code == 101010 & female == 1 & single == 1)
	gen mvd_female_married    = (loc_code == 101010 & female == 1 & single == 0)
	gen mvd_male_single       = (loc_code == 101010 & female == 0 & single == 1)
	gen mvd_male_married      = (loc_code == 101010 & female == 0 & single == 0)

	* Design: poor_single (women)
	gen mvd_poor_single       = (loc_code == 101010 & female == 1 & pobre == 1 & single == 1)
	gen mvd_poor_married      = (loc_code == 101010 & female == 1 & pobre == 1 & single == 0)
	gen mvd_rich_single       = (loc_code == 101010 & female == 1 & pobre == 0 & single == 1)
	gen mvd_rich_married      = (loc_code == 101010 & female == 1 & pobre == 0 & single == 0)

	* Design: lowed_single (women)
	gen mvd_lowed_single      = (loc_code == 101010 & female == 1 & lowed == 1 & single == 1)
	gen mvd_lowed_married     = (loc_code == 101010 & female == 1 & lowed == 1 & single == 0)
	gen mvd_highed_single     = (loc_code == 101010 & female == 1 & lowed == 0 & single == 1)
	gen mvd_highed_married    = (loc_code == 101010 & female == 1 & lowed == 0 & single == 0)
	
    save ..\base\ech_final_98_2016.dta, replace 
end

main_assign_treatment
