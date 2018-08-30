clear all
set more off

program main
	import_and_process_data
	build_figure
end

program import_and_process_data
	import excel using "..\..\..\raw\fernandez_misoprostol.xlsx", ///
	    sheet("Sheet1") firstrow clear
		
	gen norm_sales2002 = 100
	gen norm_sales2007 = norm_sales2002 + perc
	gen sales_miso_only2002 = (sales_miso_only2007 * norm_sales2002) / norm_sales2007
	gen ug_per_pop2002 = sales_miso_only2002 / world_bank_pop2002
	gen ug_per_pop2007 = sales_miso_only2007 / world_bank_pop2007
	
	drop world_bank* sales_miso* perc
	
	reshape long norm_sales ug_per_pop, i(Region) j(year)
	
	label var ug_per_pop "Misoprostol (in µg × 10^6) / Population (in millions)"
	label var year "Year"
end

program build_figure

    generate order = 1 if Region =="Global"
    replace order = 2 if Region =="Latin America"
    replace order = 3 if Region =="Chile"
    replace order = 4 if Region =="Uruguay"

    graph bar norm_sales, over(year) ///
	    over(Region, sort(order) descending) ///
	    asyvars graphregion(fcolor(white) lcolor(white)) ///
		ytitle("Misoprostol annual sales (base 2002)") name(bar) 
		
	graph export ../output/misoprostol_sales_2002_2007.pdf, replace
	
    graph twoway connected ug_per_pop year if Region == "Global" || ///
	    connected ug_per_pop year if Region == "Latin America" || ///
        connected ug_per_pop year if Region == "Uruguay" || ///
		connected ug_per_pop year if Region == "Chile", ///
		legend(label(1 "Global") label(2 "Latin America") label(3 "Uruguay") label(4 "Chile")) ///
		xlabel(2002(5)2007) graphregion(fcolor(white) lcolor(white)) name(dots)

	graph export ../output/misoprostol_per_capita_2002_2007.pdf, replace
end

main


main
