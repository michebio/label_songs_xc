update.packages(oldPkgs = c("tuneR", "seewave", "warbleR", "rjson",
                            "askpass", "credentials", "curl",
                            "evaluate", "gert", "knitr", "openssl",
                            "pkgload", "withr", "boot", "rpart"), ask = FALSE, lib = Sys.getenv("R_LIBS_USER"))

#### check observer is correct ####
#### 
check_observed_id <- function(x){
  test = sort(c("MB", "JYB", "SC", "LB", "AE", "JC", "AG", "SM", "LS", "FS"))
  if(!is.character(x)) {
    print(paste0("the observer name is of class ", class(x), " but expected character"))
    stop(paste0("the observer name is of class ", class(x), " but expected character"))
  }
  if(!any(x == test)) {
    print(paste0(c("the observer name is ", x, " but expected either ", test), collapse = " "))
    stop(paste0(c("the observer name is ", x, " but expected either ", test), collapse = " "))
  }
  return(TRUE)
}


#### error handiling for warbleR::query_xc when download fails because of time out####
# 
# 

check_download <- function(down, path_sp, path_save_error_files){
  
  fls_down = list.files(path_sp)
  if(!any(stringr::str_detect(fls_down, paste0(down$Recording_ID)))){
    warbleR::query_xc(X = down, path = normalizePath(path_sp))
    return(0)
  } else {
    print(paste0("Recordind_ID ", down$Recording_ID, " already downloaded"));
    return(paste0("Recordind_ID ", down$Recording_ID, " already downloaded"))
  }
  
}

try_query_xc <- function(down, path_sp, path_save_error_files){
  tryCatch( { 
    check_download(down, path_sp, path_save_error_files)
  }, 
  error = function(e) {
    if(!dir.exists(path_save_error_files)) dir.create(path_save_error_files)
    out_path = paste0(normalizePath(path_save_error_files), "/", down$Recording_ID, ".csv")
    if(file.exists(out_path)) unlink(out_path)
    data.table::fwrite(down, out_path)
  message(paste0("++++++++++ try_query_xc error: could not download Recording_ID", down$Recording_ID))
  })
}



#### script to download files from XC based on criteria ####
#### 
download_xc_by_sp <- function(i, list_species, dt, convert_to_wav = FALSE){
  if(!dir.exists("xc/")) dir.create("xc/")
  #if(!dir.exists("error_handling/")) dir.create("error_handling/")
  
  #if(!dir.exists("derived_data/xc/all_df")) dir.create("derived_data/xc/all_df")
  sp_target = list_species[i]
  basic_name = stringr::str_replace_all(sp_target, " ", "_")
  basic_name = stringr::str_replace_all(basic_name, "-", "_")
  basic_name = stringr::str_replace_all(basic_name, "'", "_")
  dt0 = subset(dt, English_name == sp_target)
  if(nrow(dt0) == 0){
    msg = paste0("species ", basic_name, " not found in data frame, with index ", i)
    print(msg)
    return(msg)
  }
  path_sp0 = paste0("xc/", basic_name)
  if(!dir.exists(path_sp0)) dir.create(path_sp0)
  expected_file_nam = data.table::data.table(file_out_name = paste0(normalizePath(path_sp0), "/", basic_name, ".csv"))
  label_dir = list.dirs(path = ".", full.names = TRUE, recursive = FALSE)
  label_dir = normalizePath(label_dir[stringr::str_detect(label_dir, "labels_")])
  label_dir = paste0(label_dir, "/", basic_name)
  if(length(label_dir) > 1) {print("Multiple directories contain the string labels. Please delete manually created directories containing the string labels and re-run the script."); stop("")}
  if(!dir.exists(label_dir)) dir.create(label_dir)
  # err_h = paste0("error_handling/outputs_file_names_for_ref_", basic_name, ".csv")
  # if(!file.exists(err_h)){
  #   data.table::fwrite(expected_file_nam, err_h)
  # } else {
  #   already_written = data.table::fread(err_h)
  #   expected_file_nam = data.table::rbindlist(list(already_written, expected_file_nam), fill = TRUE)
  #   data.table::fwrite(expected_file_nam, err_h)
  # }
  #if(dir.exists(path_sp0)) unlink(path_sp0, recursive = TRUE)
  path_sp = paste0("xc/", basic_name, "/recordings")
  if(!dir.exists(path_sp)) dir.create(path_sp)
  path_save_error_files = paste0("errors_download_xc")
  # if(!dir.exists(path_save_error_files)) dir.create(path_save_error_files)
  
  for(index in 1:nrow(dt0)){
    
    down = dt0[index, .(latin, English_name, 
                        Recording_ID, Genus,
                        Specific_epithet, Time)]
    try_query_xc(down, path_sp, path_save_error_files)
  }
  if(processing_sp_with_few_recordings){
    data.table::setcolorder(dt0, c("Recording_ID", "birdlife_sci_name", 
                                   "English_name", "song_description_collins_bird_guide",  
                                   "jean_roche", "cd", "short_or_continuous_song", "Vocalization_type",
                                   "snr_freq"))
  } else{
    data.table::setcolorder(dt0, c("Recording_ID", "birdlife_sci_name", 
                                 "English_name", "song_description_collins_bird_guide",  
                                 "jean_roche", "cd", "short_or_continuous_song", "Vocalization_type",
                                 "count_other_species", "snr_freq", "Length"))
  }
  file_out_path = paste0(normalizePath(path_sp0), "/", basic_name, ".csv")
  if(file.exists(file_out_path)) unlink(file_out_path)
  data.table::fwrite(dt0, file_out_path)
  if(processing_sp_with_few_recordings){
  openxlsx::write.xlsx(as.data.frame(dt0), paste0(normalizePath(path_sp0), "/", basic_name, "_all_recordings.xlsx"),
                       overwrite = TRUE)
  } else {
    openxlsx::write.xlsx(as.data.frame(dt0), paste0(normalizePath(path_sp0), "/", basic_name, ".xlsx"),
                         overwrite = TRUE)    
  }
  # check all files where downloaded and if not attempt to download them again!
  fls_down = list.files(path_sp)
  ids_dwon = as.integer(stringr::str_extract(fls_down, "\\d+"))
  downloaded_fls = data.table(Recording_ID = ids_dwon, downloaded_file = TRUE)
  dt1 = merge(dt0, downloaded_fls, all = T)
  if(any(is.na(dt1$downloaded_file))){
    download_again = subset(dt1, is.na(downloaded_file))
    for(index in 1:nrow(download_again)){
      down = download_again[index, .(latin, English_name, 
                          Recording_ID, Genus,
                          Specific_epithet, Time)]
      try_query_xc(down, path_sp, path_save_error_files)
    }
  }
  print(paste0("downloaded ", sp_target))
  if(file.exists(paste0(normalizePath(path_sp0), "/", basic_name, ".csv"))) {
    print("and csv correctly written!") } else {
      print("CSV not written!")
    }
  print("=================================================")
  return(0)
}



# replace spaces name

get_clean_nam = function(x){
  y = stringr::str_replace_all(x, " ", "_")
  y = stringr::str_replace_all(y, "-", "_")
  y = stringr::str_replace_all(y, "'", "_")
  return(y)
}

##### run some checks and background code #####
##### 
source("src_files/run_some_checks.R")