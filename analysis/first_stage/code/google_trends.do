clear all
set more off

program main
	import delimited using "..\..\..\raw\google_trends.csv", clear ///
		 rowrange(4:180) colrange(1:3) varnames(3)   
	label var abortionuruguay "Abortion"
	label var misoprostoluruguay "Misoprostol"
	replace misoprostoluruguay = "1" if misoprostoluruguay=="<1"
	destring misoprostoluruguay, replace
	gen date = monthly(month,"YM")
	format %tm date
	label var date "Month"
	drop month
		
	tw line abortion misoprostol date if date<ym(2013,12), ///
		tline(2004m04 2005m04 2006m10 2007m10 2008m11 2012m09 2013m06, lc(black) lp(dot)) ///
		tmlab(2004m04 "(a)" 2005m04 "(b)" 2006m10 "(c)" 2007m10 "(d)" 2008m11 "(e)" ///
		2012m09 "(f)" 2013m06 "(g)", tp(inside) labs(*0.9) labgap(*.3)) ///
		tlabel(2004m01(36)2013m01) ttick(#10) lc(blue red) graphregion(fc(white) lc(white))
	graph export ../output/google_trends.pdf, replace

end

main
