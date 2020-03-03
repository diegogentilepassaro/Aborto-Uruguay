clear all
set more off
adopath + ..\..\..\library\stata\gslab_misc\ado

program main
	use "..\..\..\derived\Vitals\output\births.dta", clear

	gen_and_label
	build_plots
end

program gen_and_label
    collapse (count) births = edadm, by(anio dpto dpto_residence)
	egen births_tot = total(births), by(anio dpto_residence)
	gen births_sh = births/births_tot
	
	gen tag_same = dpto_residence==dpto
	gen tag_mvd  = dpto==1
	gen births_sh_same = births/births_tot if tag_same
	gen births_sh_mvd  = births/births_tot if tag_mvd

	collapse (max) births_sh_same births_sh_mvd, by(anio dpto_residence)
	xtset dpto_residence anio
	label var anio "Birth year"
	label var births_sh_same "Share of births in same state"
	label var births_sh_mvd  "Share of births in Montevideo"
	label var dpto_residence "Mother's residential state"
end 

program build_plots
	foreach x in same mvd {
		egen min_sh_`x' = min(births_sh_`x'), by(dpto_residence)
		qui sum min_sh_`x', det
		gen tag_`x' = (min_sh_`x'> r(p50))
	}

	local plot_lines  = "plot1(lp(shortdash)) plot2(lp(shortdash)) plot3(lp(shortdash)) plot4(lp(shortdash)) plot5(lp(shortdash))"
	local legend_all  = "legend(cols(7) symx(3) si(vsmall) bex)"
	local legend_mvd  = "legend(off)"
	local legend_same = "legend(rows(3) symx(5) si(small))"
	local legend_mvd  = "legend(off)"
	foreach x in same mvd {
		xtline births_sh_`x', ov ylabel(0 (.2) 1 ) name(`x') ///
			graphregion(color(white)) `legend_all' `plot_lines'
		qui sum births_sh_`x'
		local min_`x' = floor(`r(min)'*5) / 5
		forvalues tag = 0/1 {
			xtline births_sh_`x' if tag_`x'==`tag', ov ylabel(`min_`x'' (.2) 1 ) name(`x'_`tag') ///
				graphregion(color(white)) `legend_`x''
		}
	}
	
	graph combine mvd_0 mvd_1 same_0 same_1, ysiz(6) xsiz(10) graphregion(color(white)) scale(0.8) 
	graph export "..\output\births_sh_2groups.pdf", replace

	grc1leg same mvd, rows(1) legendfrom(same) position(6) cols(2) graphregion(color(white))
	graph export "..\output\births_sh_1group.pdf", replace

	graph drop same_0 same_1 mvd_0 mvd_1 same mvd
end

* EXECUTE
main
