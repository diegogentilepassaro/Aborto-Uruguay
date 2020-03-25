clear all
set more off

program main
    clean_data
    plot_natality, rescale(1000)
end

program clean_data
	import excel using "..\..\..\raw\Cuadro 5. Tasas Brutas de Mortalidad y Natalidad. Uruguay, 1996-2015.xlsx" ///
		  , clear cellrange(a39:bi62)

	local i = 0
	foreach x of varlist * {
	   rename `x' var`i'
	   local i = `i' + 1
	}

	rename var0 dpto

	local j1 = 2
	forvalues year = 1996/2015 {
		local j0 = `j1' - 1
		local j2 = `j1' + 1
		replace var`j1' = "`year'" if mi(var`j1') in 1
		replace var`j2' = "`year'" if mi(var`j2') in 1
		assert var`j0'[1] == var`j1'[1] & var`j1'[1] == var`j2'[1]
		rename var`j0' nat_level`year'
		rename var`j1' population`year'
		rename var`j2' nat_rate`year'
		local j1 = `j1' + 3
	}

	drop in 22/23
	drop in 1/2 

	destring , replace
	local nn=_N+1
	set obs `nn'
	replace dpto = "Montevideo, Canelones y San Jose" in `nn'
	forvalues year = 1996/2015 {
		replace nat_level`year' = nat_level`year'[2] + nat_level`year'[10] + nat_level`year'[16] in `nn'
		replace population`year' = population`year'[2] + population`year'[10] + population`year'[16] in `nn'
	}

	foreach var in nat_level nat_rate population {
		preserve 
			keep    dpto `var'*
			reshape long `var', i(dpto) j(year)
			tempfile     `var'
			save        ``var''
		restore
	}
	
	use `nat_level', clear
	merge 1:1 dpto year using `nat_rate'  , nogen assert(3)
	merge 1:1 dpto year using `population', nogen assert(3)

	encode dpto, g(dpto_num)
	xtset  dpto_num year
	replace nat_rate = nat_level/population*1000
end

program plot_natality
syntax, rescale(int)
	gen nat_level_`rescale'= nat_level/`rescale'
	label var nat_level_`rescale' "Births (`rescale's)"
	local opts = "overlay graphregion(fcolor(white) lcolor(white)) ylab(#3) legend(rows(1))"
	local opt1 = "plot1(recast(con) lc(blue) mc(blue)) "
    local opt2 = "plot1(recast(con) lc(red) mc(red)) "

	xtline nat_level_`rescale' if (dpto=="Montevideo") & inrange(year,2000,2009) ///
		, `opts' `opt1' tline(2004, lcolor(black) lpattern(dot)) name(mvd, replace) ///
		subtitle("Montevideo")
	xtline nat_level_`rescale' if (dpto=="Canelones") & inrange(year,2000,2009) ///
		, `opts' `opt1' tline(2004, lcolor(black) lpattern(dot)) name(can, replace) ///
		subtitle("Canelones")	
	xtline nat_level_`rescale' if (dpto=="San Jose") & inrange(year,2000,2009) ///
		, `opts' `opt1' tline(2004, lcolor(black) lpattern(dot)) name(san, replace) ///
		subtitle("San Jose")	
	xtline nat_level_`rescale' if (dpto=="Florida") & inrange(year,2004,2011) ///
		, `opts' `opt1' tline(2008, lcolor(black) lpattern(dot)) name(flo, replace) ///
		subtitle("Florida")
	xtline nat_level_`rescale' if (dpto=="Rivera") & inrange(year,2006,2013) ///
		, `opts' `opt1' tline(2010, lcolor(black) lpattern(dot)) name(riv, replace) ///
		subtitle("Rivera")
	xtline nat_level_`rescale' if (dpto=="Salto") & inrange(year,2008,2015) ///
		, `opts' `opt2' tline(2012, lcolor(black) lpattern(dot)) name(sal, replace) ///
		subtitle("Salto")
		
	graph combine mvd can san flo riv sal, cols(3) ysize(7) xsize(10) ///
	graphregion(fcolor(white)) ///
	graph export ../output/natality_`rescale'.png, replace
	graph drop _all
end

main
