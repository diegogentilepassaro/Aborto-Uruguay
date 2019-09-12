clear all
set more off
adopath + ../../../library/stata/gslab_misc/ado

program main
    clean_data

    preserve
    keep if dpto == 99
    drop dpto
    save_data ../output/total_aggregate_births.dta, key(anio) replace
    restore

    keep if dpto != 99
    save_data ../output/by_year_dpto_aggregate_births.dta, key(anio dpto) replace
end

program clean_data
    import excel using "../../../raw/Cuadro 5. Tasas Brutas de Mortalidad y Natalidad. Uruguay, 1996-2015.xlsx" ///
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

    gen dpto_num = 1 if dpto == "Montevideo"
    replace dpto_num = 2 if dpto == "Artigas"
    replace dpto_num = 3 if dpto == "Canelones"
    replace dpto_num = 4 if dpto == "Cerro Largo"
    replace dpto_num = 5 if dpto == "Colonia"
    replace dpto_num = 6 if dpto == "Durazno"
    replace dpto_num = 7 if dpto == "Flores"
    replace dpto_num = 8 if dpto == "Florida"
    replace dpto_num = 9 if dpto == "Lavalleja"
    replace dpto_num = 10 if dpto == "Maldonado"
    replace dpto_num = 11 if dpto == "Paysandu"
    replace dpto_num = 12 if dpto == "Rio Negro"
    replace dpto_num = 13 if dpto == "Rivera"
    replace dpto_num = 14 if dpto == "Rocha"
    replace dpto_num = 15 if dpto == "Salto"
    replace dpto_num = 16 if dpto == "San Jose"
    replace dpto_num = 17 if dpto == "Soriano"
    replace dpto_num = 18 if dpto == "Tacuarembo"
    replace dpto_num = 19 if dpto == "Treinta y tres"
	replace dpto_num = 99 if dpto == "Total"
    drop if missing(dpto_num)
    drop dpto
    rename dpto_num dpto

    rename year anio
    xtset  dpto anio
    replace nat_rate = nat_level/population*1000
end

*EXECUTE
main
