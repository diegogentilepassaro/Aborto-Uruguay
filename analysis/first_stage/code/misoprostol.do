clear all
set more off

program main
    use ../../../base/Misoprostol/output/misoprostol.dta, clear
    build_figure
end

program build_figure

    generate order = 1 if region =="Global"
    replace order = 2 if region =="Latin America"
    replace order = 3 if region =="Chile"
    replace order = 4 if region =="Uruguay"

    graph bar norm_sales, over(year) ///
        over(region, sort(order) descending) ///
        asyvars graphregion(fcolor(white) lcolor(white)) ///
        ytitle("Misoprostol annual sales (base 2002)")
        
    graph export ../output/misoprostol_sales_2002_2007.pdf, replace
    
    graph twoway connected ug_per_pop year if region == "Global" || ///
        connected ug_per_pop year if region == "Latin America" || ///
        connected ug_per_pop year if region == "Uruguay" || ///
        connected ug_per_pop year if region == "Chile", ///
        legend(label(1 "Global") label(2 "Latin America") label(3 "Uruguay") label(4 "Chile")) ///
        xlabel(2002(5)2007) graphregion(fcolor(white) lcolor(white)) ///
        xline(2003.5, lcolor(black) lpattern(dot)) text(8.3 2003.5 "IS start") ///
        ytitle("Misoprostol (in µg × 10^6) / Population (in millions)", size(small))

    graph export ../output/misoprostol_per_capita_2002_2007.pdf, replace
end

main
