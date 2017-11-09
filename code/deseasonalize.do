clear all
set more off

program main_deseasonalize
    local outcomes = "trabajo horas_trabajo"

    use "..\base\ech_final_98_2016.dta", clear

    deseasonalize, outcomes(`outcomes')
	
	save "..\base\ech_final_98_2016.dta", replace
	
end

program deseasonalize  
    syntax, outcomes(str)
	
	foreach outcome in `outcomes' {
		gen unadj_`outcome' = `outcome'

	    qui sum `outcome' if anio < 2004
		local mean = r(mean)
		
		reg unadj_`outcome' i.trimestre if anio < 2004
		predict p_`outcome', resid
		
		replace `outcome' = p_`outcome' + `mean' if anio < 2004
	    drop p_`outcome'
		
		qui sum `outcome' if anio >= 2004
		local mean = r(mean)
		
		reg unadj_`outcome' i.trimestre if anio >= 2004
		predict p_`outcome', resid
		
		replace `outcome' = p_`outcome' + `mean' if anio >= 2004		
	}
end

main_deseasonalize
