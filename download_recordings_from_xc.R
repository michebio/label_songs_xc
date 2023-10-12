#' R script to download selected recordings from Xeno-Canto for the
#' Acoucene project https://www.fondationbiodiversite.fr/en/the-frb-in-action/programs-and-projects/le-cesab/acoucene/
#' at the FRB-CESAB https://www.fondationbiodiversite.fr/en/
#' email: michela.busana@fondationbiodiversite.fr
#' The code has been tested on R v. 4.3.1 on Ubuntu and Windows

#### manually set observer name: ####
#### by uncommenting your initials, i.e. delete the # sign at the beginning of the line with your initials
# observer = "MB" #  
# observer = "JYB" 
# observer = "SC" 
# observer = "LB" 
# observer = "AE" 
# observer = "JC" 
# observer = "AG" 
# observer = "SM" 
# observer = "LS" 
# observer = "FS"    

#### 
# example to test the protocol
list_species = c("Eurasian Reed Warbler", "Eurasian Skylark", "European Pied Flycatcher", "Common Chaffinch", "Black Redstart") 

if(!require("pacman")) install.packages("pacman")
pacman::p_load(data.table, stringr, tuneR, seewave, NatureSounds, warbleR, tidyr, openxlsx, rjson)
dt = data.table::fread("derived_data/list_of_all_xc_files.csv")

# load available functions
source("src_files/functions.R")

# download all species XC
for(i in 1:length(list_species)){
  tryCatch( { download_xc_by_sp(i = i, list_species = list_species, dt = dt, convert_to_wav = FALSE) }
            , error = function(e) {message(paste0("++++++++++ could not download ", list_species[i], 
                                                  " with index ", i))})
}
message("done!")


