clear all
set more off
adopath + ../../library/stata/gslab_misc/ado

program main_assign_treatment
    add_impl_date
    assign_treatment
end

program add_impl_date
	import excel ..\..\raw\timeline_implementation.xlsx, clear firstrow cellrange(D1:E14)
	keep if !mi(impl_date)
	bys dpto: egen impl_date_dpto = min(impl_date)
	format %td impl_date_dpto
	keep *dpto
	duplicates drop
	isid dpto
	tempfile impl_date_dpto
	save `impl_date_dpto'

	use ..\..\derived\output\clean_loc_1998_2016.dta, clear 
	merge m:1 dpto using `impl_date_dpto', assert(1 3) nogen
    save_data ..\temp\clean_loc_1998_2016_impl_date.dta, key(numero pers anio) replace 
end

program assign_treatment
    use ..\temp\clean_loc_1998_2016_impl_date.dta, clear 
	
	* Dates of treatments
	do ../../analysis/globals.do

	* Variables for the triple diff
	gen fertile_age = (inrange(edad, 16, 45)) if inrange(edad,16,60)
	gen female      = (hombre==0)             if !mi(hombre)
	gen single      = (married==0)            if !mi(married)
	gen lowed       = (educ_level==1)         if !mi(educ_level)
	gen young       = (inrange(edad, 16, 30)) if inrange(edad,16,45)
	
	gen yob = anio-edad
	foreach city in rivera salto florida {
		gen age_`city'     = ${y_date_`city'} - yob
		gen under14_`city' = (inrange(age_`city',0,14))
		bys anio numero: egen nbr_under14_`city' = total(under14_`city')
		gen kids_`city' = (nbr_under14_`city' > 0)
	}
	
	* Diff in Diff Rivera , Salto , Florida
	local restr         " & inrange(edad, 16, 45)"
	local restr_young   " & inrange(edad, 16, 30)"
	local restr_adult   " & inrange(edad, 31, 45)"
	local restr_placebo " & inrange(edad, 46, 60)"

	foreach age_group in "" "_young" "_adult" "_placebo" {
		local value = 0
		foreach var in treatment placebo {
			if "`var'"=="placebo" & inlist("`age_group'","_young","_adult","_placebo") {
				continue
			}
			else {
				local subsample " hombre == `value'  `restr`age_group''"
				gen `var'`age_group'_rivera  = (loc_code == 1313020) if (inlist(loc_code,1313020,431050,202020)   & `subsample') //*rio branco 431050 *artigas    202020
				gen `var'`age_group'_salto   = (loc_code == 1515020) if (inlist(loc_code,1515020,1111020,1212020) & `subsample') //*paysandu 1111020  *fray bentos 1212020
				gen `var'`age_group'_florida = (loc_code == 808220)  if (inlist(loc_code,808220,1919020)   & `subsample')

				gen `var'_c`age_group'_rivera  = (loc_code == 1313020) if (inlist(loc_code,1313020,431050,202020)   & `subsample') //*rio branco 431050 *artigas    202020
				gen `var'_c`age_group'_salto   = (loc_code == 1515020) if (inlist(loc_code,1515020,1111020,1212020) & `subsample') //*paysandu 1111020  *fray bentos 1212020
				gen `var'_c`age_group'_florida = (loc_code == 808220)  if (inlist(loc_code,808220,1919020)   & `subsample')

				gen `var'_d`age_group'_rivera  = (dpto == 13) if (inlist(dpto,13,4,2)   & `subsample')
				gen `var'_d`age_group'_salto   = (dpto == 15) if (inlist(dpto,15,11,12) & `subsample')
				gen `var'_d`age_group'_florida = (dpto == 8)  if (inlist(dpto,8,19)   & `subsample')
			}
			local value = 1
		}
	}

    save_data ..\output\ech_final_98_2016.dta, key(numero pers anio) replace 
end

main_assign_treatment

/*
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
	gen mvd_poor_kids       = (loc_code == 101010 & female == 1 & poor == 1 & ind_under14 == 1)
	gen mvd_poor_nokids     = (loc_code == 101010 & female == 1 & poor == 1 & ind_under14 == 0)
	gen mvd_nonpoor_kids    = (loc_code == 101010 & female == 0 & poor == 0 & ind_under14 == 1)
	gen mvd_nonpoor_nokids  = (loc_code == 101010 & female == 0 & poor == 0 & ind_under14 == 0)


