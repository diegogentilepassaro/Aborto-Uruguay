clear all
set more off
adopath + ../../../library/stata/gslab_misc/ado

	use "..\..\..\derived\output\births.dta", clear
	drop if inlist(depar,20,99) // drop Extranjero, No indicado

	collapse (count) births = edadm, by(anio codep depar)
	egen births_tot = total(births), by(anio depar)
	gen births_sh = births/births_tot
	
	gen tag_same = depar==codep
	gen tag_mvd  = codep==10
	gen births_sh_same = births/births_tot if tag_same
	gen births_sh_mvd  = births/births_tot if tag_mvd

	collapse (max) births_sh_same births_sh_mvd, by(anio depar)
	xtset depar anio
	label var anio "Birth year"
	label var births_sh_same "Share of births in same state"
	label var births_sh_mvd  "Share of births in Montevideo"

	foreach var in same mvd {
		egen min_sh_`var' = min(births_sh_`var'), by(depar)
		qui sum min_sh_`var', det
		gen tag_`var' = (min_sh_`var'> r(p50))
	}

	foreach var in same mvd {
		forvalues tag = 0/1 {
			sum births_sh_`var'
			local y_min = floor(`r(min)'*5) / 5
			xtline births_sh_`var' if tag_`var'==`tag', ov ylabel(`y_min' (.2) 1 ) legend(rows(3) symx(5) si(small)) name(`var'_`tag')
		}
		graph combine `var'_0 `var'_1
		graph export "..\output\births_sh_`var'_depar.pdf", replace
		graph drop `var'_0 `var'_1
	}

