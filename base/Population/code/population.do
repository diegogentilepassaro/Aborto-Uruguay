clear all
set more off
adopath + ../../../library/stata/gslab_misc/ado

program main
    import_and_append
    rename_years
    reshape_agg_and_save
end

program import_and_append
    local S_all   = 0
    local S_men   = 22
    local S_women = 44

    * Create the cell range for each of the 6 tables in each worksheet
    foreach gender in all men women {
        local S0_`gender' = 8 + `S_`gender''
        local S1_`gender' = `S0_`gender''+2
        local E1_`gender' = `S0_`gender''+2+18
        local cr1_`gender' = "A`S0_`gender'':Z`S0_`gender''"
        local cr2_`gender' = "A`S1_`gender'':Z`E1_`gender''"
    }

    * Get names and number of worksheets to be later used as indicators
    import excel "../../../raw/Departamentos_poblacion_por_sexo_y_edad_1996-2025.xls" , describe
    local ws_N = `r(N_worksheet)'-1
    local ws_1 = 3

    forvalues ws = `ws_1'/`ws_N' {
        local ws_`ws'_name = "`r(worksheet_`ws')'"
        local ws_`ws'_nbr  = `ws'
        if `ws'==3 {
            local ws_`ws'_dpto = 1 //Mvd
        }
        else {
            local ws_`ws'_dpto = `ws'-2
        }
    }

    * Import the 6 tables from each worksheet and create the relevant variables 
    forvalues ws = `ws_1'/`ws_N' {
        foreach gender in all men women {
            foreach cr in 1 2 {
                import excel "../../../raw/Departamentos_poblacion_por_sexo_y_edad_1996-2025.xls" ///
                 , clear sheet("`ws_`ws'_name'") cellrange(`cr`cr'_`gender'')
                
                gen depar = `ws_`ws'_dpto'
                gen gender_all = "`gender'"
                
                if "`cr'" == "1" {
                    gen age_min    = 0
                    gen age_max    = 99
                    gen all_ages   = 1
                }
                else {        
                    qui replace A="90-99" if A=="90 y más"
                    gen splitat    = strpos(A,"-")    
                    gen age_min    = substr(A,1,splitat-1)
                    gen age_max    = substr(A,splitat+1,.)
                    qui destring age_min age_max, replace
                    drop splitat
                    gen all_ages   = 0
                }
                
                tempfile pop_`ws_`ws'_nbr'_`gender'_`cr'
                save `pop_`ws_`ws'_nbr'_`gender'_`cr''
                
                di "*******"
                di "pop_`ws_`ws'_nbr'_`gender'_`cr'"
                di "*******"
            }
        }
    }

    * Append all tables
    use `pop_`ws_1'_all_1', clear
    forvalues ws = `ws_1'/`ws_N' {
        foreach gender in all men women {
            foreach cr in 1 2 {
                if "`ws_`ws'_nbr'_`gender'_`cr'" == "`ws_1'_all_1" {
                    continue
                }
                else {
                    append using `pop_`ws_`ws'_nbr'_`gender'_`cr''
                }
            }
        }
    }
    drop A    
end

program rename_years
    local year = 1996
    foreach k in `c(ALPHA)' {
        if "`k'" == "A" {
            continue
        }
        else {
            rename `k' pop`year'
            local year = `year' + 1
        }
    }
end 

program reshape_agg_and_save
    * Reshape, aggregate dy depto, and save table
    rename (depar gender_all) (dpto category)
    reshape long pop, i(dpto category age_min age_max) j(anio)

    create_panel, by(anio) by_name(year)
    create_panel, by(anio dpto) by_name(year_dpto)
end

program create_panel
    syntax, by(str) by_name(str)

    preserve 
    collapse (sum) pop if (category=="all" & all_ages == 1), by(`by')
    save "../temp/by_`by_name'_population.dta", replace
    restore 

    preserve 
    collapse (sum) pop if (category=="women" & all_ages == 1), by(`by')
    rename pop women_pop
    save "../temp/by_`by_name'_women_population.dta", replace
    restore

    preserve 
    collapse (sum) pop if (category=="women" & age_min>=15 & age_max<45 & all_ages==0), by(`by')
    rename pop fertile_women_pop
    save "../temp/by_`by_name'_fertile_women_population.dta", replace
    restore

    preserve
    use "../temp/by_`by_name'_population.dta", clear
    merge 1:1 `by' using "../temp/by_`by_name'_women_population.dta", nogen ///
        keepusing(women_pop) assert(3)
    merge 1:1 `by' using "../temp/by_`by_name'_fertile_women_population.dta", nogen ///
        keepusing(fertile_women_pop) assert(3)
    save_data ../output/by_`by_name'_population.dta, key(`by') replace    
    restore     
end 

* EXECUTE
main
