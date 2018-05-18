clear all
set more off
adopath + ../../library/stata/gslab_misc/ado

program main_assign_treatment
    do ../../analysis/globals.do
    clean_impl_date
    assign_treatment_births
    assign_treatment_ech
end

program clean_impl_date
	import excel ..\..\raw\timeline_implementation.xlsx, clear firstrow cellrange(D1:E14)
	keep if !mi(impl_date)
	bys dpto: egen impl_date_dpto = min(impl_date)
	format %td impl_date_dpto
	keep *dpto
	duplicates drop
	save_data ..\temp\timeline_implementation.dta, key(dpto) replace
end

program new_age_vars
syntax, age_var(string)
	assert !mi(`age_var')
	gen yob = anio - `age_var'
	gen age_young   = inrange(`age_var',16,30)
	gen age_adult   = inrange(`age_var',31,45)
	gen age_placebo = inrange(`age_var',46,60)
	gen fertile_age = inrange(`age_var',16,45) if inrange(`age_var',16,60)
	egen    age_group = cut(`age_var') , at(16(5)50)
	replace age_group = age_group+2

	lab def age_young                 0 "Age: 31-45"             1 "Age: 16-30"
	lab val age_young                 age_young
end

program assign_treatment_births
	use ..\..\derived\output\births_derived.dta, clear
	merge m:1 dpto using ..\temp\timeline_implementation.dta, assert(1 3) nogen
	new_age_vars, age_var(edadm)
	rename yob yobm

	* TC groups
	local restr         ""
	local restr_young   " & age_young==1"
	local restr_adult   " & age_young==0"
	foreach age_group in "" "_young" "_adult" {
		gen treatment_rivera`age_group'  = (dpto == 13 `restr`age_group'') if inlist(dpto,13,4,2)
		gen treatment_salto`age_group'   = (dpto == 15 `restr`age_group'') if inlist(dpto,15,11,12)
		gen treatment_florida`age_group' = (dpto == 8  `restr`age_group'') if inlist(dpto,8,5,7)
		lab define treatment_rivera`age_group' 0 "Control`age_group'" 1 "Rivera`age_group'" 
		lab define treatment_salto`age_group' 0 "Control`age_group'" 1 "Salto`age_group'" 
	}

	preserve
		replace edadm = 15 if inrange(edadm,0,14)
		replace edadm = 49 if inrange(edadm,50,99)
		keep if inrange(edadm,15,49) 
		egen age_group15 = cut(edadm) ,at(15(5)50)
		bys age_group15: egen age_min = min(edadm)
		bys age_group15: egen age_max = max(edadm)
		save "..\output\births15.dta", replace
	restore

	keep if inrange(edadm,16,45)
	save "..\output\births.dta", replace
end

program assign_treatment_ech
    use ..\..\derived\output\clean_loc_1998_2016.dta, clear 
	merge m:1 dpto using ..\temp\timeline_implementation.dta, assert(1 3) nogen
	new_age_vars, age_var(edad)

	* Variables for the triple diff
	gen female      = (hombre==0)             if !mi(hombre)
	gen single      = (married==0)            if !mi(married)
	gen lowed       = (educ_level==1)         if !mi(educ_level)
	gen young       = (inrange(edad, 16, 30)) if inrange(edad,16,45)
	
	foreach city in rivera salto florida {
		gen age_`city'     = ${y_date_`city'} - yob
		gen under14_`city' = (inrange(age_`city',0,14))
		bys anio numero: egen nbr_under14_`city' = total(under14_`city')
		gen kids_`city' = (nbr_under14_`city' > 0)
	}
	
	* TC groups
	local restr         " & inrange(edad, 16, 45)"
	local restr_young   " & age_young==1 "
	local restr_adult   " & age_adult==1 "
	local restr_placebo " & age_placebo==1 "

	foreach age_group in "" "_young" "_adult" "_placebo" {
		local value = 0
		foreach var in treatment placebo {
			if "`var'"=="placebo" & inlist("`age_group'","_young","_adult","_placebo") {
				continue
			}
			else {
				local subsample " hombre == `value'  `restr`age_group''"
				*gen `var'`age_group'_rivera  = (loc_code == 1313020) if (inlist(loc_code,1313020,431050,202020)   & `subsample') //*rio branco 431050 *artigas    202020
				*gen `var'`age_group'_salto   = (loc_code == 1515020) if (inlist(loc_code,1515020,1111020,1212020) & `subsample') //*paysandu 1111020  *fray bentos 1212020
				*gen `var'`age_group'_florida = (loc_code == 808220)  if (inlist(loc_code,808220,505320,707320)    & `subsample')

				gen `var'`age_group'_rivera_c  = (loc_code == 1313020) if (inlist(loc_code,1313020,431050,202020)   & `subsample') //*rio branco 431050 *artigas    202020
				gen `var'`age_group'_salto_c   = (loc_code == 1515020) if (inlist(loc_code,1515020,1111020,1212020) & `subsample') //*paysandu 1111020  *fray bentos 1212020
				gen `var'`age_group'_florida_c = (loc_code == 808220)  if (inlist(loc_code,808220,505320,707320)    & `subsample')

				gen `var'`age_group'_rivera_s  = (dpto == 13) if (inlist(dpto,13,4,2)   & `subsample')
				gen `var'`age_group'_salto_s   = (dpto == 15) if (inlist(dpto,15,11,12) & `subsample')
				gen `var'`age_group'_florida_s = (dpto == 8)  if (inlist(dpto,8,5,7)    & `subsample')
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


