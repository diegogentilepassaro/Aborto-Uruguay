clear all
set more off
cd "C:\Users\dgentil1\Desktop\aborto_uru_repo\Aborto-Uruguay\code"
*cd "C:\Users\cravizza\Google Drive\Projects\proyecto_aborto\Aborto-Uruguay\code"

program main 
	do clean_raw.do
	do append_person_years
	do homogeneize_geo_vars
	do assign_treatment
end

main
