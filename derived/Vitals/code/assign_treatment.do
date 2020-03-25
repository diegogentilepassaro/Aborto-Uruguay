clear all
set more off
adopath + ../../../library/stata/gslab_misc/ado

program main 
    import_treatment_dates
    assign_treatment
    
    save_data ../temp/vital_birth_records.dta, key(birth_id) replace
end

program import_treatment_dates
    import excel ../../../raw/timeline_implementation.xlsx, clear firstrow cellrange(D1:E14)
    keep if !mi(impl_date)
    
    bys dpto: egen impl_date_dpto = min(impl_date)
    gen IS_impl_date = impl_date_dpto
    format %td IS_impl_date

    keep dpto IS_impl_date
    duplicates drop
    save_data ../temp/timeline_implementation.dta, key(dpto) replace

    import excel ../../../raw/control_impl_dates.xlsx, clear firstrow
    keep dpto impl_date
	keep if !missing(dpto)
    save_data ../temp/timeline_control_implementation.dta, key(dpto) replace
end

program assign_treatment
    use ../../../base/Vitals/output/vital_birth_records.dta, clear
    merge m:1 dpto using ../temp/timeline_implementation.dta, ///
        keepusing(IS_impl_date)
    gen montevideo = (dpto == 1)        
    gen treated = (_merge == 3 & dpto != 1)
    drop _merge
    merge m:1 dpto using ../temp/timeline_control_implementation.dta, ///
        keepusing(impl_date)
    replace IS_impl_date = impl_date if _merge == 3
    gen control = (_merge == 3)
    drop impl_date _merge
    gen treated_or_control = (treated == 1 | control == 1)
    
    relative_time, event_date(IS_impl_date) time(anio_qtr) time_fun(qofd) window(12)
    relative_time, event_date(IS_impl_date) time(anio_sem) time_fun(hofd) window(6)
    relative_time, event_date(IS_impl_date) time(anio) time_fun(yofd) window(4)

    /*gen VTP_impl_date = td(01jan2013)
    format %td VTP_impl_date*/
end

program relative_time
    syntax, event_date(str) time(str) time_fun(str) window(int) 
  
    gen rel_t_`time' = `time' - `time_fun'(`event_date') if !missing(IS_impl_date)
    bysort dpto: gen post_`time' = (`time' >= `time_fun'(`event_date'))    
    replace rel_t_`time' = -1000    if rel_t_`time' < -`window' & !missing(IS_impl_date)
    replace rel_t_`time' = 1000 if rel_t_`time' >  `window' & !missing(IS_impl_date)
    replace rel_t_`time' = rel_t_`time' + `window' + 1 if ///
        (rel_t_`time' != -1000 & rel_t_`time' != 1000 & !missing(IS_impl_date)) ///
        
    replace rel_t_`time' = 0 if rel_t_`time' == -1000 & !missing(IS_impl_date)
    assert !mi(rel_t_`time') if !missing(IS_impl_date)
    tab rel_t_`time', m
end

* EXECUTE
main
