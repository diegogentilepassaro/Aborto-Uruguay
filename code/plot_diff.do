clear all
set more off

program main_diff_plot
	plot_diff
end

program plot_diff
   	use  ..\base\ech_final_98_2016.dta, clear
	
	*reg trabajo i.salto_city##i.post_ive i.anio_qtr i.dpto [aw = pesotri]	

	keep if treatment_salto==1 | treatment_rivera==1 | control_paysandu==1 /*we don't actually need this*/
	
	* Collapse such that we get a different row for different study groups
	collapse (mean) trabajo estudiante [aw = pesotri] ///
		, by(anio_qtr treatment_salto treatment_rivera control_paysandu)
		
	twoway (line trabajo anio_qtr if treatment_salto  == 1) ///
	       (line trabajo anio_qtr if control_paysandu == 1)
	
end

main_diff_plot
