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
	replace dpto = "Area Metropolitana" in `nn'
	forvalues year = 1996/2015 {
		replace nat_level`year' = nat_level`year'[2] + nat_level`year'[10] in `nn'
		replace population`year' = population`year'[2] + population`year'[10] in `nn'
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
	gen nat_rate2 = nat_level/population*1000
end

program plot_natality
syntax, rescale(int)
	gen nat_level_`rescale'= nat_level/`rescale'
	label var nat_level_`rescale' "Births (`rescale's)"
	xtline nat_level_`rescale' if (dpto=="Total"|dpto=="Montevideo") & inrange(year,2000,2006) ///
		, overlay graphregion(fcolor(white) lcolor(white)) tline(2004) name(tot, replace) ///
		ylab(20(20)60) legend(on rows(1))
	xtline nat_level_`rescale' if (dpto=="Total"|dpto=="Montevideo") & inrange(year,2008,2014) ///
		, overlay graphregion(fcolor(white) lcolor(white)) tline(2012) name(mvd, replace) ///
		ylab(20(20)60) legend(on rows(1))
	xtline nat_level_`rescale' if (dpto=="Rivera"|dpto=="Artigas") & inrange(year,2006,2012) ///
		, overlay graphregion(fcolor(white) lcolor(white)) tline(2010) name(rivera, replace) ///
		ylab(#3) legend(rows(1))
	xtline nat_level_`rescale' if (dpto=="Salto"|dpto=="Paysandu") & inrange(year,2008,2014) ///
		, overlay graphregion(fcolor(white) lcolor(white)) tline(2012) name(salto, replace) ///
		ylab(#3) legend(rows(1))
	graph combine tot mvd rivera salto, cols(2) ysize(7) xsize(10) graphregion(fcolor(white))
	graph export ../output/natality_`rescale'.pdf, replace
end

main
