clear all
set more off

program main
	import_and_process_data
	build_figure
end

program import_and_process_data
	import excel using "..\..\..\raw\fernandez_misoprostol.xlsx", ///
	    sheet("Sheet1") firstrow clear
	
	keep Region perc
	
	gen norm_sales2002 = 100
	gen norm_sales2007 = norm_sales2002 + perc
	
	reshape long norm_sales, i(Region) j(year)
	
	label var norm_sales "Change in Misoprostol annual sales"
	label var year "Year"
end

program build_figure
    graph twoway line norm_sales year if Region == "Global" || ///
	    line norm_sales year if Region == "Latin America" || ///
        line norm_sales year if Region == "Uruguay" || ///
		line norm_sales year if Region == "Chile", ///
		legend(label(1 "Global") label(2 "Latin America") label(3 "Uruguay") label(4 "Chile")) ///
		xlabel(2002(5)2007) graphregion(fcolor(white) lcolor(white))

	graph export ../output/misoprostol_sales_2002_2007.pdf, replace
end

main
