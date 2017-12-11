clear all
set more off
adopath + ../../library/stata/gslab_misc/ado

program main_assign_treatment
    assign_treatment
end

program assign_treatment
    use ..\..\derived\output\clean_loc_1998_2016.dta, clear 

	* Variables for the triple diff
	gen fertile_age = (inrange(edad, 16, 45)) if inrange(edad,16,60)
	gen female      = (hombre==0)             if !mi(hombre)
	gen single      = (married==0)            if !mi(married)
	gen lowed       = (educ_level==1)         if !mi(educ_level)
	gen young       = (inrange(edad, 16, 30)) if inrange(edad,16,45)
	gen kids        = (ind_under14 == 1)
	
	* Dates of treatments
	global q_date_mvd    "2004q2"
	global q_date_rivera "2010q3"
	global q_date_salto  "2013q1"
	
	global s_date_mvd    "2004h1"
	global s_date_rivera "2010h2"
	global s_date_salto  "2013h1"
	
	global y_date_mvd    2004 
	global y_date_rivera 2010 
	global y_date_salto  2013 
	
	* Diff in Diff Rivera y Salto
	gen treatment_rivera = (loc_code == 1313020 & hombre == 0)
    gen treatment_salto  = (loc_code == 1515020 & hombre == 0)

    gen control_rivera  = ((loc_code == 431050 | loc_code == 202020) & hombre == 0)
    gen control_salto   = ((loc_code == 1111020 |loc_code ==1212020) & hombre == 0)

	gen treatment_placebo_rivera   = (loc_code == 1313020 & hombre == 0 & fertile_age == 0)
    gen treatment_placebo_salto    = (loc_code == 1515020 & hombre == 0 & fertile_age == 0)
    gen control_placebo_rivera  = ((loc_code == 431050 | loc_code == 202020) & hombre == 0 & fertile_age == 0)
    gen control_placebo_salto   = ((loc_code == 1111020 |loc_code ==1212020) & hombre == 0 & fertile_age == 0)	


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
	gen treatment_mvd_female  = (dpto == 1 & female == 1)
	gen treatment_mvd_poor    = (dpto == 1 & female == 1 & poor == 1)
	gen treatment_mvd_fertile = (dpto == 1 & female == 1 & fertile_age == 1)
	gen treatment_mvd_kids    = (dpto == 1 & female == 1 & ind_under14 == 1)	
	gen treatment_mvd_lowed   = (dpto == 1 & female == 1 & lowed == 1)
	gen treatment_mvd_single  = (dpto == 1 & female == 1 & single == 1)
	gen treatment_mvd_student = (dpto == 1 & female == 1 & estudiante == 1)

	gen control_mvd_female    = (dpto == 1 & female == 0)
	gen control_mvd_poor      = (dpto == 1 & female == 1 & poor == 0)
	gen control_mvd_fertile   = (dpto == 1 & female == 1 & fertile_age == 0)
	gen control_mvd_kids      = (dpto == 1 & female == 1 & ind_under14 == 0)		
	gen control_mvd_lowed     = (dpto == 1 & female == 1 & lowed == 0)
    gen control_mvd_single    = (dpto == 1 & female == 1 & single == 0)
	gen control_mvd_student   = (dpto == 1 & female == 1 & estudiante == 0)
	
	* Triple Diff
	
	/** Design 2: income_fertility (only women)
	gen mvd_poor_fertile       = (loc_code == 101010 & poor == 1 & fertile_age == 1 & hombre == 0)
	gen mvd_poor_infertile     = (loc_code == 101010 & poor == 1 & fertile_age == 0 & hombre == 0)
	gen mvd_non_poor_fertile   = (loc_code == 101010 & poor == 0 & fertile_age == 1 & hombre == 0)
	gen mvd_non_poor_infertile = (loc_code == 101010 & poor == 0 & fertile_age == 0 & hombre == 0)
  	
	* Design 3: gender_fertility
	gen mvd_female_fertile    = (loc_code == 101010 & hombre == 0 & fertile_age == 1)
	gen mvd_female_infertile  = (loc_code == 101010 & hombre == 0 & fertile_age == 0)
	gen mvd_male_fertile      = (loc_code == 101010 & hombre == 1 & fertile_age == 1)
	gen mvd_male_infertile    = (loc_code == 101010 & hombre == 1 & fertile_age == 0)     
    */	
	
	/* Design: female_poor
	gen mvd_female_poor       = (loc_code == 101010 & female == 1 & poor == 1)
	gen mvd_female_rich       = (loc_code == 101010 & female == 1 & poor == 0)
	gen mvd_male_poor         = (loc_code == 101010 & female == 0 & poor == 1)
	gen mvd_male_rich         = (loc_code == 101010 & female == 0 & poor == 0)*/
	
	* Design: female_single
	gen mvd_female_single     = (loc_code == 101010 & female == 1 & single == 1)
	gen mvd_female_married    = (loc_code == 101010 & female == 1 & single == 0)
	gen mvd_male_single       = (loc_code == 101010 & female == 0 & single == 1)
	gen mvd_male_married      = (loc_code == 101010 & female == 0 & single == 0)
	
	/* Design: female_lowed
	gen mvd_female_lowed      = (loc_code == 101010 & female == 1 & lowed == 1)
	gen mvd_female_highed     = (loc_code == 101010 & female == 1 & lowed == 0)
	gen mvd_male_lowed        = (loc_code == 101010 & female == 0 & lowed == 1)
	gen mvd_male_highed       = (loc_code == 101010 & female == 0 & lowed == 0)

	* Design: poor_single (women)
	gen mvd_poor_single       = (loc_code == 101010 & female == 1 & poor == 1 & single == 1)
	gen mvd_poor_married      = (loc_code == 101010 & female == 1 & poor == 1 & single == 0)
	gen mvd_rich_single       = (loc_code == 101010 & female == 1 & poor == 0 & single == 1)
	gen mvd_rich_married      = (loc_code == 101010 & female == 1 & poor == 0 & single == 0)
	
	* Design: poor_lowed (women)
	gen mvd_poor_lowed       = (loc_code == 101010 & female == 1 & poor == 1 & lowed == 1)
	gen mvd_poor_highed      = (loc_code == 101010 & female == 1 & poor == 1 & lowed == 0)
	gen mvd_rich_lowed       = (loc_code == 101010 & female == 1 & poor == 0 & lowed == 1)
	gen mvd_rich_highed      = (loc_code == 101010 & female == 1 & poor == 0 & lowed == 0)

	* Design: lowed_single (women)
	gen mvd_lowed_single      = (loc_code == 101010 & female == 1 & lowed == 1 & single == 1)
	gen mvd_lowed_married     = (loc_code == 101010 & female == 1 & lowed == 1 & single == 0)
	gen mvd_highed_single     = (loc_code == 101010 & female == 1 & lowed == 0 & single == 1)
	gen mvd_highed_married    = (loc_code == 101010 & female == 1 & lowed == 0 & single == 0)*/

	* Design: young_kids (women)
	gen mvd_young_kids      = (loc_code == 101010 & female == 1 & young == 1 & ind_under14 == 1)
	gen mvd_young_nokids    = (loc_code == 101010 & female == 1 & young == 1 & ind_under14 == 0)
	gen mvd_old_kids        = (loc_code == 101010 & female == 0 & young == 0 & ind_under14 == 1)
	gen mvd_old_nokids      = (loc_code == 101010 & female == 0 & young == 0 & ind_under14 == 0)	

	* Design: young_poor (women)
	gen mvd_young_poor      = (loc_code == 101010 & female == 1 & young == 1 & ind_under14 == 1)
	gen mvd_young_nopoor    = (loc_code == 101010 & female == 1 & young == 1 & ind_under14 == 0)
	gen mvd_old_poor        = (loc_code == 101010 & female == 0 & young == 0 & ind_under14 == 1)
	gen mvd_old_nopoor      = (loc_code == 101010 & female == 0 & young == 0 & ind_under14 == 0)	

	* Design: poor_kids (women)
	gen mvd_poor_kids      = (loc_code == 101010 & female == 1 & poor == 1 & ind_under14 == 1)
	gen mvd_poor_nokids    = (loc_code == 101010 & female == 1 & poor == 1 & ind_under14 == 0)
	gen mvd_nonpoor_kids        = (loc_code == 101010 & female == 0 & poor == 0 & ind_under14 == 1)
	gen mvd_nonpoor_nokids      = (loc_code == 101010 & female == 0 & poor == 0 & ind_under14 == 0)
    save_data ..\output\ech_final_98_2016.dta, key(numero pers anio) replace 
end

main_assign_treatment
