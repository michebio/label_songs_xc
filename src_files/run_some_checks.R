if(!exists("observer")) stop("Please specify who you are within the observer variable, i.e. uncomment the line at the top of the script containing your initials")
check_observed_id(observer)
path_lab = paste0("labels_", observer)
if(!dir.exists(path_lab)) dir.create(path_lab)
if(!dir.exists("xc")) dir.create("xc")
# set to TRUE when downloading species with few recordings manually
processing_sp_with_few_recordings = FALSE