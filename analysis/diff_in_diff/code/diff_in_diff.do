clear all
set more off
adopath + ../../../library/stata/gslab_misc/ado

program main_diff_analysis
    do ../../globals.do
    local labor_vars   = "trabajo horas_trabajo"
    local educ_vars    = "educ_HS_or_more educ_more_HS"
    local outcome_vars = "`labor_vars' " + "`educ_vars'"
    local labor_stubs  = `" "Employment" "Hours-worked" "'
    local educ_stubs   = `" "High-school" "Some-college" "'
    local labor_restr "inrange(edad, 16, 45)"
    local labor_restr_mvd "inrange(edad, 16, 45)"    
    local educ_restr "inrange(edad, 18, 25)"

    foreach city in rivera salto {
        
        foreach group_vars in labor /*educ*/ {

            plot_diff, outcomes(``group_vars'_vars') treatment(`city') time(anio_sem) plot_option(trend) ///
                stubs(``group_vars'_stubs') restr(``group_vars'_restr') groups_vars(`group_vars') 

            /*plot_diff, outcomes(``group_vars'_vars') treatment(`city') time(anio) plot_option(trend) ///
                stubs(``group_vars'_stubs') restr(``group_vars'_restr') groups_vars(`group_vars') */

            reg_diff, outcomes(``group_vars'_vars') treatment(`city') time(anio_sem) ///
                restr(``group_vars'_restr') groups_vars(`group_vars')

            /*reg_diff, outcomes(``group_vars'_vars') treatment(`city') time(anio) ///
                restr(``group_vars'_restr') groups_vars(`group_vars')*/
        }
    }

    /*foreach demo in kids female single { 
         
        foreach group_vars in labor /*educ*/ {

            plot_diff, outcomes(``group_vars'_vars') treatment(mvd_`demo') time(anio_sem) plot_option(trend) ///
                stubs(``group_vars'_stubs') restr(``group_vars'_restr') groups_vars(`group_vars') 

            /*plot_diff, outcomes(``group_vars'_vars') treatment(`city') time(anio) plot_option(trend) ///
                stubs(``group_vars'_stubs') restr(``group_vars'_restr') groups_vars(`group_vars') */

            reg_diff, outcomes(``group_vars'_vars') treatment(mvd_`demo') time(anio_sem)   ///
                restr(``group_vars'_restr') groups_vars(`group_vars')

            /*reg_diff, outcomes(``group_vars'_vars') treatment(`city') time(anio)  ///
                restr(``group_vars'_restr') groups_vars(`group_vars')*/
        }
    }*/
end

program plot_diff
    syntax , outcomes(string) stubs(string) treatment(string) time(string) plot_option(str) ///
         [groups_vars(str) restr(string) sample(str)]

       use  ..\..\..\assign_treatment\output\ech_final_98_2016.dta, clear
    
    cap keep if `restr'
    
    keep if !mi(treatment_`treatment')
    
    if "`time'" == "anio_qtr" {
        local weight pesotri
        local range "if inrange(`time', tq(${q_date_`treatment'}) - ${q_pre},tq(${q_date_`treatment'}) + ${q_post}) "
        local xtitle "Year-qtr"
        local vertical = tq(${q_date_`treatment'}) - 0.5
        local vertical2= tq(${q_date_`treatment'}) + 2.5  
    }
    else if "`time'" == "anio_sem" {
        local weight pesosem
        local range "if inrange(`time', th(${s_date_`treatment'}) - ${s_pre},th(${s_date_`treatment'}) + ${s_post}) "
        local xtitle "Year-half"
        local vertical = th(${s_date_`treatment'}) - 0.5
        local vertical2= th(${s_date_`treatment'}) + 1.5     
    }
    else {
        local weight pesoan
        local range "if inrange(`time', ${y_date_`treatment'} - ${y_pre}, ${y_date_`treatment'} + ${y_post}) "
        local xtitle "Year"
        local vertical = ${y_date_`treatment'} - 0.5
        local vertical2= ${y_date_`treatment'} + 0.5   
    }
    
    save ..\temp\did_sample.dta, replace
            
    local n_outcomes: word count `outcomes'
    
    forval i = 1/`n_outcomes' {
        local outcome: word `i' of `outcomes'
        local stub_var: word `i' of `stubs'

        use ..\temp\did_sample.dta, clear
        
        if "`plot_option'" == "diff" {
            preserve
                collapse (mean) `outcome' (sd) sd_`outcome' = `outcome' (count) n_`outcome' = `outcome' ///
                    [aw = `weight'] if treatment_`treatment' == 1 , by(`time')
                rename *`outcome' *`outcome'_t
                save ../temp/treat_`outcome'_ts.dta, replace            
            restore
            
            collapse (mean) `outcome' (sd) sd_`outcome' = `outcome' (count) n_`outcome' = `outcome' ///
                [aw = `weight'] if treatment_`treatment' == 0 , by(`time')
            rename *`outcome' *`outcome'_c
            merge 1:1 `time' using ../temp/treat_`outcome'_ts.dta, ///
                assert(3) keep(3) nogen
                
            gen `outcome'_diff = `outcome'_t - `outcome'_c
            gen `outcome'_diff_se = sqrt((sd_`outcome'_t^2/n_`outcome'_t)+(sd_`outcome'_c^2/n_`outcome'_c))
        
            gen `outcome'_diff_ci_p = `outcome'_diff + 1.96 * `outcome'_diff_se
            gen `outcome'_diff_ci_n = `outcome'_diff - 1.96 * `outcome'_diff_se            
        
            qui twoway (rarea `outcome'_diff_ci_p  `outcome'_diff_ci_n `time' `range', fc(green)  lc(bg)    fin(inten20)) ///
                       (line  `outcome'_diff                      `time' `range', lc(green)  lp(solid) lw(medthick)), ///
                legend(on order(2) label(2 "Difference between treatment and control")) ///
                tline(`vertical'  `vertical2', lcolor(black) lpattern(dot)) ///
                graphregion(color(white)) bgcolor(white) xtitle("`xtitle'") ///
                ytitle("`stub_var'") name(diff_`outcome'_`treatment', replace) ///
                title("`stub_var'", color(black) size(medium)) ylabel()
                
                local diff_stub "diff_"
        }
        else {    
            preserve
                collapse (mean) `outcome' (sem) se_`outcome'=`outcome' [aw = `weight'] if treatment_`treatment' == 1 , by(`time')
                tsset `time'
                tssmooth ma `outcome' = `outcome', window(1 1 0) replace
                gen treat = 1
                save ../temp/treat_`outcome'_ts.dta, replace
            restore
            
            collapse (mean) `outcome' (sem) se_`outcome'=`outcome' [aw = `weight'] if treatment_`treatment' == 0 , by(`time')
            tsset `time'
            tssmooth ma `outcome' = `outcome', window(1 1 0) replace
            save ../temp/control_`outcome'_ts.dta, replace
            append using ../temp/treat_`outcome'_ts.dta
            replace treat = 0 if missing(treat)

            gen `outcome'_ci_p = `outcome' + 1.96*se_`outcome'
            gen `outcome'_ci_n = `outcome' - 1.96*se_`outcome'
            
            if "`treatment'" == "mvd_female" {
                if "`outcome'" == "trabajo" {
                    local ylabel "0.5 (0.1) 0.8"
                }
                else if "`outcome'" == "horas_trabajo" {
                    local ylabel "16 (8) 40"
                }            
            }
            else if "`treatment'" == "mvd_single" | "`treatment'" == "mvd_lowed" | "`treatment'" == "mvd_poor" {
                if "`outcome'" == "trabajo" {
                    local ylabel "0.4 (0.2) 0.8"
                }
                else if "`outcome'" == "horas_trabajo" {
                    local ylabel "12 (8) 28"
                }            
            }
            else if "`treatment'" == "placebo_rivera" {
                if "`outcome'" == "trabajo" {
                    local ylabel "0.65 (0.2) 0.85"
                }
                else if "`outcome'" == "horas_trabajo" {
                    local ylabel "30 (8) 38"
                }            
            }
            else {
                if "`outcome'" == "trabajo" {
                    local ylabel "0.4 (0.1) 0.6"
                }
                else if "`outcome'" == "horas_trabajo" {
                    local ylabel "12 (8) 28"
                }
            }
            
            qui twoway (scatter  `outcome' `time' `range' & treat == 1, mc(blue) lp(solid) lw(medthick)) ///
                       (scatter  `outcome' `time' `range' & treat == 0, mc(red)  lp(solid) lw(medthick)) ///
                       (line     `outcome' `time' `range' & treat == 1, lc(blue) lp(solid) lw(thin)) ///
                       (line     `outcome' `time' `range' & treat == 0, lc(red)  lp(solid) lw(thin)) ///
                ,legend(on order(1 2) label(1 "Treatment") label(2 "Control") size(vlarge) width(90) forcesize) ///
                tline(`vertical' `vertical2', lcolor(black) lpattern(dot)) ///
                graphregion(color(white)) bgcolor(white) xtitle("`xtitle'", size(vlarge)) ///
                ytitle("`stub_var'", size(vlarge)) name(`outcome'_`treatment', replace) ///
                title("`stub_var'", color(black) size(vlarge)) ylabel(`ylabel', labs(large)) ///
                xlabel(#7, labs(large)) xtitle(, size(vlarge))         
        }
        }
        
        forval i = 1/`n_outcomes' {
            local outcome: word `i' of `outcomes'
            local plots = "`plots' " + "`diff_stub'`outcome'_`treatment'"
        }
            
        local plot1: word 1 of `plots'     
        
        grc1leg `plots', rows(`n_outcomes') legendfrom(`plot1') position(6) cols(2) /// /* cols(1) or cols(3) */
               graphregion(color(white)) title({bf: ${legend_`treatment'} `special_legend'}, color(black) size(vlarge))
        graph display, ysize(3) xsize(7)
        graph export ../output/did_`diff_stub'`treatment'_`groups_vars'_`time'.pdf, replace            
        
end

program reg_diff
    syntax, outcomes(string) treatment(string) time(string) [groups_vars(str) restr(string) sample(str)]
        
        use  ..\..\..\assign_treatment\output\ech_final_98_2016.dta, clear
        
        *cap keep if `restr'
        
        if "`time'" == "anio_qtr" {
                local weight pesotri
                local range "if inrange(`time', tq(${q_date_`treatment'}) - ${q_pre},tq(${q_date_`treatment'}) + ${q_post}) "
                qui sum `time' `range'
                local min_year = year(dofq(r(min)))
            }
            else if "`time'" == "anio_sem" {
                local weight pesosem
                local range "if inrange(`time', th(${s_date_`treatment'}) - ${s_pre},th(${s_date_`treatment'}) + ${s_post}) "
                qui sum `time' `range'
                local min_year = year(dofh(r(min)))
            }
            else {
                local weight pesoan
                local range "if inrange(`time', ${y_date_`treatment'} - ${y_pre}, ${y_date_`treatment'} + ${y_post}) "
                qui sum `time' `range'    
                local min_year = r(min)
            }

        if `min_year' < 2001  {
            local control_vars " c98_* "
            }
        else if `min_year' >=2001 & `min_year' < 2006  {
            local control_vars " c98_* c01_* "
            }
        else {
            local control_vars " c98_* c01_* c06_* "
            }
        
        local n_outcomes: word count `outcomes'
		clear matrix
        forval i = 1/`n_outcomes' {
            local outcome: word `i' of `outcomes'
            
            if "`time'" == "anio_qtr" {
                    gen post = (`time' >= tq(${q_date_`treatment'}))
                } 
                else if "`time'" == "anio_sem" {
                    gen post = (`time' >= th(${s_date_`treatment'}))
                }
                else {
                    gen post = (`time' >= ${y_date_`treatment'})
                }
           
		    foreach cond in "" "& kids_`treatment' == 1" "& kids_`treatment' == 0" "& single == 0" "& single == 1" /*"& young == 0" "& young == 1"*/ {
                
                foreach age_group in "_young" "_adult" "_placebo" {

                    gen interaction = treatment`age_group'_`treatment' * post

                    reg `outcome' i.treatment`age_group'_`treatment' i.post interaction ///
                        i.`time' nbr_people ind_under14 edad married y_hogar_alt `control_vars' ///
                        `range' `cond' & !mi(treatment`age_group'_`treatment') ///
						[aw = `weight'], vce(cluster `time')
			
                    matrix COLUMN`age_group' = ((_b[interaction] \ _se[interaction]) \ e(N))
            
                    drop interaction
                }
    			
                matrix COLUMN = (COLUMN_young , COLUMN_adult, COLUMN_placebo)
                matrix ROW = (nullmat(ROW) \ COLUMN)
			}
			
            matrix TABLE = (nullmat(TABLE) , ROW)
			matrix drop ROW
			drop post
        }
			
		matrix_to_txt, matrix(TABLE) saving("../output/tables.txt") append ///
			 title(<tab:did_`treatment'>)
        
//         esttab using ../output/did_`treatment'_`groups_vars'_`time'.tex, label se ar2 compress ///
//             replace nonotes coeflabels(interaction "${legend_`treatment'} x Post") ///
// 			keep(interaction) star(* 0.1 ** 0.05 *** 0.01) ///
// 			mtitles("Employment women" "Employment men" "Hours worked women" "Hours worked men")
//         eststo clear
end

main_diff_analysis
