library(haven)

main <- function () {
    for (year in 2006:2016) {
        if (year == 2016) {
            data <- read_spss(paste0('../../../raw/HyP_', year ,'_TERCEROS.sav'))
        } else {
            data <- read_spss(paste0('../../../raw/FUSIONADO_', year ,'_TERCEROS.sav'))
        }
        write_dta(data,paste0('../temp/raw_', year ,'.dta'))
    }
}

main()

quit()
