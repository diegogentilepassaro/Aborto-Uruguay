clear all
set more off
cd "C:\Users\dgentil1\Desktop\aborto_uru_repo\Aborto-Uruguay\code"
*cd "C:\Users\cravizza\Google Drive\Projects\proyecto_aborto\Aborto-Uruguay\code"

program main 
	*do clean_raw
	do append_years
	do homogeneize_geo_vars
	do prepare_for_analysis
	do assign_treatment
	do plot_diff
	do SCM
	do triple_diff
end

main
