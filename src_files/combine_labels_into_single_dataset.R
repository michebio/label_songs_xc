###### script to combine the labels from all species into a unique dataset of labels #######
###### 
###### 
library(data.table)
rm(list = ls())
get_clean_nam = function(x){
  y = stringr::str_replace_all(x, " ", "_")
  y = stringr::str_replace_all(y, "-", "_")
  y = stringr::str_replace_all(y, "'", "_")
  return(y)
}
### list labels dir
ldir = list.dirs(".", full.names = TRUE, recursive = FALSE)
ldir = normalizePath(ldir[stringr::str_detect(ldir, "labels_")])

ldir = data.table(full_path_dirs = ldir, relp = stringr::str_remove_all(ldir, paste0(getwd(), "/")))
ldir[, labeler := stringr::str_remove_all(stringr::str_split(relp, "\\/", simplify=T)[,1], "labels_")]
# list txt files with labels
txts = list.files(".", full.names = TRUE, recursive = TRUE, pattern = ".txt")
txts = normalizePath(txts[stringr::str_detect(txts, "labels_")])
txts = data.table(full_path_lbl = txts, relp = stringr::str_remove_all(txts, paste0(getwd(), "/")))
txts[, labeler := stringr::str_remove_all(stringr::str_split(relp, "\\/", simplify=T)[,1], "labels_")]
txts[, species := stringr::str_split(relp, "\\/", simplify=T)[,2]]
txts[, file_nam := stringr::str_split(relp, "\\/", simplify=T)[,3]]
txts[, Recording_ID := (stringr::str_remove_all((stringr::str_split(relp, "\\/", simplify=T)[,3]), ".txt"))]
txts[!stringr::str_detect(Recording_ID, "^[:digit:]+$"), rec_from := "cd"]
txts[stringr::str_detect(Recording_ID, "^[:digit:]+$"), rec_from := "xc"]
txts[rec_from == "cd", Recording_ID := "-1"]
txts[, Recording_ID := as.numeric(Recording_ID)]
txts[Recording_ID==-1,]
txts[Recording_ID!=-1,]


path_tmp = "derived_data/tmp_4_appending_labels"
if(dir.exists(path_tmp)) unlink(path_tmp, recursive = TRUE)
if(!dir.exists(path_tmp)) dir.create(path_tmp)
i = 1

for(i in 1:nrow(txts)){
  print(i)
  lbl = read.table(txts[i, full_path_lbl], sep = "\t")
  names(lbl) = c("min_t", "max_t", "label_id")
  lbl = as.data.table(lbl)
  lbl[, rec_from := txts[i, rec_from]]
  lbl[, channel := "1"]
  lbl[, Recording_ID := txts[i, Recording_ID]]
  lbl[Recording_ID == -1, channel := "L"]
  lbl[stringr::str_detect(label_id, "L"), channel := "L"]
  lbl[stringr::str_detect(label_id, "R"), channel := "R"]
  lbl[stringr::str_detect(label_id, "B"), channel := "L"]
  lbl[stringr::str_detect(label_id, "T"), channel := "R"]
  if(any(lbl$channel == "L")){
    lbl[channel == "1", channel := "L"]
  } else if(any(lbl$channel == "R")){
    lbl[channel == "1", channel := "R"]
  }
  
  lbl[, species := txts[i, species]]
  lbl[, labeler := txts[i, labeler]]
  lbl[, file_nam_label := txts[i, file_nam]]
  fwrite(lbl, paste0(normalizePath(path_tmp), "/", unique(txts[i, species]), "_", 
                     unique(txts[i, Recording_ID]), ".csv"))
}

print("for loop ended successfully!")

fls = list.files(path_tmp, full.names = TRUE, pattern = ".csv$")
dt = rbindlist(lapply(fls, fread), fill = TRUE)
dt = unique(dt)

# add location of wav files
loc_wav = normalizePath("../abundance/xc")
fls = list.files(loc_wav, pattern = ".wav$", recursive = TRUE)
if(length(fls) == 0){
  stop(paste0("the path ", loc_wav, " does not contain any wav file!"))
}
fls = fls[stringr::str_detect(fls, "converted")]
wav_file_nam = data.table(wav_file = fls, Recording_ID = as.integer(stringr::str_extract(fls, "\\d+")))
wav_file_nam[, full_path := paste0(loc_wav, "/", wav_file)]
wav_file_nam[, check_nam := stringr::str_split(wav_file, "\\/", simplify=T)[,1]]

dt = merge(dt, unique(wav_file_nam[, .(Recording_ID, full_path, check_nam)]), by = "Recording_ID", all.x = TRUE)

# add location of cd
loc_wav = normalizePath("../songs_CD")
fls = list.files(loc_wav, pattern = ".wav$", recursive = TRUE, full.names = TRUE)
out = stringr::str_split(fls, "\\/", simplify = TRUE)
wav_file_nam = data.table(wav_file_cd = fls, file_nam_label = stringr::str_replace(out[, ncol(out)], ".wav", ".txt"))

dt[ , file_nam_label := trimws(file_nam_label, which = "right", whitespace = "\\~")]

if(nrow(dt[stringr::str_sub(file_nam_label,-1,-1) != "t", ])>0){
  print(dt[stringr::str_sub(file_nam_label,-1,-1) != "t", file_nam_label])
  stop(paste0("the column full_nam_label should contain only file names with extension .txt, but for the files above there is a typo!"))
}

dt = merge(dt, unique(wav_file_nam), by = "file_nam_label", all.x = TRUE)
dt[!is.na(wav_file_cd), full_path := wav_file_cd]
if(any(is.na(dt$full_path))) {
  print("Missing wav file in the machine for species:")
  print(unique(dt[is.na(full_path), .(species, file_nam_label)]))
  stop("download missing files!")
}
dt[, wav_file_cd := NULL]

if(nrow(dt[rec_from == "xc" & (species != check_nam),])>0) {
  print(dt[rec_from == "xc" & (species != check_nam), .(Recording_ID, species, check_nam)])
  stop("Mismatch in species name from label and labeler!")
}


if(nrow(dt[rec_from == "cd" & is.na(full_path),])>0) {
  print(dt[rec_from == "cd" & is.na(full_path), .(Recording_ID, species, labeler)])
  stop("Missing path for songs from CD for the above files")
}


counts = dt[, .(number_of_distinct_paths = uniqueN(file_nam_label)), by = species]
print("Check species with less than 16 recordings:")
print(unique(counts[number_of_distinct_paths < 16, .(species, number_of_distinct_paths)]))


dt[, duration_song := (max_t - min_t)]
dt[, unique_id := 1:.N, by = file_nam_label]
dt[, unique_id_label := paste0(stringr::str_replace(Recording_ID, "-1", "cd"), "_", unique_id)]
dt[Recording_ID == -1, unique_id_label := paste0(species, "_", unique_id_label)]
dt[, check_nam := NULL]

# attach relevant metadata from XC
xc = fread("derived_data/list_of_all_xc_files.csv")
taxonomy = unique(xc[, .(English_name, birdlife_sci_name, order_name,  family_name, 
                  song_description_collins_bird_guide,
                  short_or_continuous_song)])
taxonomy[, species := get_clean_nam(English_name)]
taxonomy = unique(taxonomy[!is.na(birdlife_sci_name)])
taxonomy = unique(taxonomy[birdlife_sci_name!=""])
if(nrow(taxonomy) != length(unique(taxonomy$species))){
  stop("duplicated species names in taxonomy file")
}
dt1 = merge(dt, taxonomy, by = "species", all.x = T)
if(nrow(dt1) != nrow(dt)) stop("added rows after mergind dt1 and dt")
xc[, Vocalization_type := stringr::str_remove_all(Vocalization_type, '\\"')]
xc = unique(xc[Recording_ID != -1, .(Recording_ID, Country, Latitude, 
                                     Longitude, Vocalization_type)])
if(nrow(xc) != length(unique(xc$Recording_ID))){
  stop("duplicated Recording_ID in xc file")
}
dt2 = merge(dt1, xc, by = "Recording_ID", all.x = TRUE)
if(nrow(dt1) != nrow(dt2)) stop("added rows after mergind dt1 and dt2")


#### ADD options for continuous songs!

cont10sec <-  subset(dt2, short_or_continuous_song == "continuous")
cont10sec[, option := "10sec"]
cont10sec[, max_t := min_t+10]
cont10sec[,duration_song := max_t-min_t]
cont10sec[, species := paste0(species, "_", option)]



contmin <- subset(dt2, short_or_continuous_song == "continuous")
contmin[, min_len := min(duration_song), by = "species"]
print(unique(contmin$species))
contmin[, option := "min_len_23.4sec"]
contmin[, max_t := min_t+min_len]
contmin[,duration_song := max_t-min_t]
contmin[, species := paste0(species, "_", option)]
print(unique(contmin$species))
conti = rbindlist(list(contmin, cont10sec), fill=TRUE)
conti[, min_len := NULL]
print(unique(conti$species))
dt3 = rbindlist(list(dt2, conti), fill = TRUE)
dt3=unique(dt3)
setkey(dt3, "species")

print(unique(dt3$species))

fwrite(dt3, "derived_data/all_labels_with_metadata.csv")

message("!done")
