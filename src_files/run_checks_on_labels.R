### Script to check that all labels are named and stored correctly ###
### i.e. check that:
### - at least 15 XC recordings + Jean Roche CD were labelled 
### - the Recording_ID are identical in the file name and in the first label within the file
### - the Recording_ID can be found in the list of recordings for that species
### - the Jean Roche song from CD was labelled
if(!require("pacman")) install.packages("pacman")
pacman::p_load(data.table, stringr, tuneR, seewave, NatureSounds, warbleR, tidyr, openxlsx)

all_dirs = normalizePath(list.dirs(path =".", full.names = TRUE, recursive = TRUE))
dir_lab = all_dirs[stringr::str_detect(all_dirs, "labels_")]
all_csv = normalizePath(list.files(path ="xc", full.names = TRUE, recursive = TRUE, pattern = ".csv$"))

for( d in 1:length(dir_lab)){
  # print(d)
  check_level = stringr::str_split(dir_lab[d], "/")
  last_lev = check_level[[1]][length(check_level[[1]])]
  # exclude the main direcory called labels_@initials
  if(!stringr::str_detect(last_lev, "labels_")){
    # make sure there are at least 16 recordings with labels
    all_lab_txt = normalizePath(list.files(dir_lab[d], full.names = TRUE))
    all_lab_txt = all_lab_txt[stringr::str_detect(all_lab_txt, ".txt")]
    len_lab = length(all_lab_txt)
    if(len_lab == 0){
      print(paste0(last_lev, " not yet labelled!"))
      print("=================================================")
      next
    } else if(len_lab > 0 & len_lab < 16){
      print(paste0(last_lev, " contains ", len_lab, " labels instead of 15 labels from XC + 1 label for the Jean Roche CD"))
      print("=================================================")
    } 
    

    # Make sure that the recording_ID is in the csv file of the species!
    my_fread = function(dt){
      DT = data.table::fread(dt)
      DT = DT[, .(Recording_ID)]
    }
    data_xc = unique(rbindlist(lapply(all_csv[stringr::str_detect(all_csv, last_lev)], my_fread), fill = TRUE))
    file_nam = list.files(dir_lab[d], full.names = FALSE)
    file_nam = file_nam[stringr::str_detect(file_nam, ".txt")]
    # make sure the JEan Roche CD was labelled
    if(!any(stringr::str_detect(file_nam, "Roch"))){
      print(paste0("For species ", last_lev, " the Jean Roche song from CD was not labelled (or the label file name was saved incorrectly)"))
      print("=================================================")
    }
    # make sure the file name and the first label have the same Recording_ID value
    # the CD from Jean Roche make an exception
    for(l in 1:length(all_lab_txt)){
      # print(paste("l ", l))
      id_from_file_nam = (stringr::str_extract(file_nam[l], "\\d+"))
      lbl = read.table(all_lab_txt[l], sep = "\t")
      lbl = as.data.table(lbl)
      names(lbl) = c("min_t", "max_t", "label_id")
      # print(id_from_file_nam)
      # print(stringr::str_extract(lbl[1, label_id], "\\d+"))
      if(!is.na(id_from_file_nam)){
        if((id_from_file_nam != stringr::str_extract(lbl[1, label_id], "\\d+"))){
          print(paste0("For species ", last_lev, " the Recording_ID used in the file name and in the label are different; i.e. check  file ", file_nam[l], " versus its first label ",  stringr::str_extract(lbl[1, label_id], "\\d+")))
          print("=================================================")
        }
        
        # check if channel is specified
        char_in_str = stringr::str_extract(lbl[1, label_id], "[A-Z]+")
        if(!is.na(char_in_str) & stringr::str_length(char_in_str) > 0){
          if(!(char_in_str == "R" | char_in_str == "L" | char_in_str == "T" | char_in_str == "B")){
            print(paste0("For species ", last_lev, " check  file ", file_nam[l], ". The first label includes the characted ", char_in_str, " but we expect this to be either R or L (we also accept T and B)"))
            print("=================================================")
          }
        }




      } else {
        # For the cd the file name and labels are only text!
        if(!stringr::str_detect(file_nam[l], "Roch")){
          print(paste0("check if ", file_nam, " is named correctly. We expect that the labels from CD include the words Jean Roche"))
          print("=================================================")
        }
      }
      # print("==========")
    
    
      # Make sure that the recording_ID is in the csv file of the species!
      if(!is.na(id_from_file_nam) & (!any(as.numeric(id_from_file_nam) == data_xc$Recording_ID))){
        print(paste0("For ", last_lev, " there is no Recording_ID ", id_from_file_nam, " according to the csv, but there is a label file named ", file_nam[l], ". Please double-check you used the correct Recording_ID"))
        print("=================================================")
      }
    }
  } else {
    txt_in_dir = list.files(dir_lab[d], pattern = ".txt$")
    if(length(txt_in_dir) > 0){
      print(paste0("Directory ", dir_lab[d], " contains the following files ", paste0(txt_in_dir, collapse = "|", " while it is expected to be empty.")))
      print("=================================================")
      }
  }
}


print("All labels have been checked. Potential warnings/errors (if any) are printed above!")