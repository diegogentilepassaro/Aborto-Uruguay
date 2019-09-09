clear all
set more off
adopath + ../../../library/stata/gslab_misc/ado

program main
    import_and_merge_data
	rename date month
    save_data ../output/google_trends.dta, key(month) 
end

program import_and_merge_data
    foreach c in uruguay brazil {
		foreach t in abortion misoprostol {
			import delimited using "../../../raw/google_trends_`t'_`c'.csv", clear ///
				 rowrange(4:180) colrange(1:2) varnames(3)   
			gen date = monthly(month,"YM")
			format %tm date
			label var date "Month"
			drop month
			capture replace `t'`c' = "1" if `t'`c'=="<1"
			destring `t'`c', replace
			tempfile `t'_`c'
			save ``t'_`c''
		}
	}
	merge 1:1 date using `misoprostol_uruguay', assert(3) nogen
	merge 1:1 date using    `abortion_uruguay', assert(3) nogen
	merge 1:1 date using    `abortion_brazil' , assert(3) nogen
end

* EXECUTE
main

