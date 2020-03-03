clear all
set more off
adopath + ../../../library/stata/gslab_misc/ado

program main	
    use "..\..\..\derived\Vitals\output\births_treated_control.dta", clear
    collapse (count) nbr_births = birth_id, by(rel_t_anio treated)
	drop if (rel_t_anio == 0 | rel_t_anio == 1000)
	save ../temp/average_births_rel.dta, replace
	plot_yearly_average, var(nbr_births) ytitle(Number of births)
	graph export ../output/births_rel.pdf, replace
	
    use "..\..\..\derived\Vitals\output\births_mvd.dta", clear
	keep if public_health == 1
    collapse (count) nbr_births = birth_id, by(rel_t_anio pereira)
	drop if (rel_t_anio == 0 | rel_t_anio == 1000)
	rename pereira treated
	save ../temp/average_births_rel_mvd.dta, replace
	plot_yearly_average, var(nbr_births) ytitle(Number of births)	
	graph export ../output/births_rel_mvd.pdf, replace
		
    use ../temp/average_births_rel.dta, clear
	append using ../temp/average_births_rel_mvd.dta
	collapse (sum) nbr_births, by(rel_t_anio treated)
	plot_yearly_average, var(nbr_births) ytitle(Number of births)
	graph export ../output/births_rel_all.pdf, replace	
end

program plot_yearly_average
    syntax, var(str) ytitle(str)
    
	sum `var' if treated == 0 & rel_t_anio < 5
	local pre_mean_control = r(mean)
	gen pre_mean_control = `pre_mean_control'
	
	sum `var' if treated == 0 & rel_t_anio >= 5
	local post_mean_control = r(mean)
	gen post_mean_control = `post_mean_control'
	
	sum `var' if treated == 1 & rel_t_anio < 5
	local pre_mean_treated = r(mean)
	gen pre_mean_treated = `pre_mean_treated'
	
	sum `var' if treated == 1 & rel_t_anio >= 5
	local post_mean_treated = r(mean)
	gen post_mean_treated = `post_mean_treated'
	
    twoway (scatter `var' rel_t_anio if treated == 0, lcol(navy)) ///
	    (line pre_mean_control rel_t_anio if rel_t_anio <= 5, lcol(navy)) ///
	    (line post_mean_control rel_t_anio if rel_t_anio >= 5, lcol(navy)) ///
	    (scatter `var' rel_t_anio if treated == 1, col(maroon)) ///
	    (line pre_mean_treated rel_t_anio if rel_t_anio <= 5, lcol(maroon)) ///
	    (line post_mean_treated rel_t_anio if rel_t_anio >= 5, lcol(maroon)), ///
		legend(order(2 "Control" 5 "Treated")) ///
		graphregion(fcolor(white) lcolor(white)) ///
		ytitle(`ytitle') ///
		xtitle("Years relative to IS") ///
		xlabel(1 "-4" 5 "0" 9 "4") xline(5, lcol(grey) lpat(dot))
end 

main
