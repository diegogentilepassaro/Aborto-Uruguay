clear all
set more off

program main
	foreach c in uruguay brazil {
		foreach t in abortion misoprostol {
			import delimited using "..\..\..\raw\google_trends_`t'_`c'.csv", clear ///
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

	local opts = "tline(2004m04 2005m04 2006m04 2007m10 2008m04 2008m11 2012m09 2013m06, lc(black) lp(dot)) " ///
			   + "tlabel(2004m01(36)2013m01) ttick(#10) lc(blue red) lp(solid dash) " ///
			   + "graphregion(fc(white) lc(white))"
	
	tw line abortionuruguay abortionbrazil date if date<ym(2013,12), `opts' ///
		tmlab(2004m04 "(a)" 2005m04 "(b)" 2006m04 "(c)" 2007m10 "(d)" 2008m04 "(e)" ///
		2008m11 "(f)" 2012m09 "(g)" 2013m06 "(h)", tp(inside) labs(*0.9) labgap(*.3)) 
	graph export ../output/google_trends_abortion.pdf, replace
	
	tw line misoprostoluruguay misoprostolbrazil date if date<ym(2013,12), `opts' ///
		tmlab(2004m04 "(a)" 2005m04 "(b)" 2006m04 "(c)" 2007m10 "(d)" 2008m04 "(e)" ///
		2008m11 "(f)" 2012m09 "(g)" 2013m06 "(h)", tp(inside) labs(*0.9) labgap(*.3))
	graph export ../output/google_trends_misoprostol.pdf, replace
end

main
