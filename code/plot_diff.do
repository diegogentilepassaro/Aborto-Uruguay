clear all
set more off

program main_diff_plot
	plot_diff
end

program plot_diff
   	use  ..\base\ech_final_98_2016.dta, clear

	collapse (mean) trabajo estudiante rivera_city post_rivera ///
	    salto_city post_salto control_paysandu [aw = pesotri], by(anio_qtr)
		
	twoway (line trabajo anio_qtr if salto_city == 1) ///
	    (line trabajo anio_qtr if control_paysandu == 1)
	
	use  ..\base\ech_final_98_2016.dta, clear

	reg trabajo (i.salto_city##i.post_salto) i.anio_qtr i.dpto [aw = pesotri]	
end

main_diff_plot
