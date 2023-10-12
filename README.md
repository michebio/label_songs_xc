# Abstract

This repository contains a protocol to:

*   download a subset of bird vocalizations from [Xeno-Canto](https://xeno-canto.org/) using R
*   label birds' vocalization using Audacity

To download the files of recordings from Xeno-Canto (XC) from R run the R script: `download_recordings_from_xc.R`.

A detailed protocol is written in the `protol.Rmd` file.



# File metadata

After downloading the recordings from XC a separate CSV/XLSX file is created for each species.
The columns of the files are:

- **Recording_ID** unique IDentifier for each recording assigned by XC
- **birdlife_sci_name** scientific name following BirdLife International's taxonomy      
- **English_name** common name 
- **song_description_collins_bird_guide**   description of the song within the Collins bird guide   
-  **jean_roche** file name within the sound CD from Jean-Roche. Useful in case of taxonomy mismatches         
-  **cd**  location of the CD file (CD are available on the [google drive](https://drive.google.com/drive/directorys/1DBdN0iFOLbMIPG9bsoa3nzzWMjubQCQM?usp=sharing))   
- Taxonomy information from XC: **latin** scientific name used in XC; **Genus** genus; **Specific_epithet** epithet; **Subspecies**  subspecies       
-  **Recordist** name of the recordist          
-  Geographical information: **Country**; **Locality**; **Latitude**;  **Longitude**; **Altitude**
-  **Vocalization_type** Description of the vocalization from the recordist      
-  **Audio_file**  https address of the file        
-  **License**  License           
-  **Url**  url address          
-  **Quality** "*Recordings are rated by quality. Quality ratings range from A (highest quality) to E (lowest quality).*" (see https://xeno-canto.org/help/search)     
-  **Time**, **Date** when was it recorded       
-  **group**  in our case, the value is always birds 
-  **sex** sex of the individual          
- **stage**   Life stage of the individual       
-  **method**   either field recording, capture in the hand, or unknown        
-  **file.name**  mp3/wav file name as in XC          
-  **Spectrogram_small**; **Spectrogram_med**; **Spectrogram_large**; **Spectrogram_full**; **osci.small**; **osci.med**; **osci.large** specifications of the spectrogram available on XC  
-  **Length**    length of the recording         
-  **Uploaded** when the recording was uploaded        
-  **Remarks**   remarks from recordist         
-  **Bird_seen** and **animal.seen** Yes/No/unknown was the individual also observed?      
-  **Playback_used**  Yes/No/unknown, if a playback was used or not      
-  **temp** temperature          
-  **regnr** "*The regnr tag can be used to search for animals that were sound recorded before ending up in a (museum) collection. This tag also accepts a 'matches' operator*" (see https://xeno-canto.org/help/search)         
-  **auto**  Yes/No/unknown              
-  **dvc**; **mic** devices used
-  **smp**   "*The smp tag can be used to search for recordings with a specific sampling rate (in Hz). For example, smp:">48000" will return hi-res recordings. Other frequencies include 22050, 44100 and multiples of 48000.*"  (see https://xeno-canto.org/help/search)
-  **Other_species**, **Other_species1**, ...,  **Other_species22** list of species different from the target species as identified by the recordist       
-  **format_audio**     format: mp3 or wav       
-  **order_name**; **family_name**; **birdlife_common_names** BirdLife Taxonomy      
-  **easy_or_difficult_song** either easy or difficult song to identify        
-  **short_or_continuous_song**  either short or continuous songs        
-  **expertise_level_labeling**  either novice or expert labeler     
-  **passing_vocalization_types**; **seconds**; **length_less_30_sec**;  **count_other_species**;  **is_france**;  **is_neighbor**;  **is_europe**; **is_neighbor_and_quality_a_and_is_seen_and_accepted_vocalization_type**;  **is_neighbor_and_quality_a_and_accepted_vocalization_type**;   **is_europe_and_quality_a_and_accepted_vocalization_type** summary columns used to sort recordings   
-  **min_amp_between_signals**;	**max_amp_between_signals**;	**min_amp_signal**;	**max_amp_signal**;	**count_number_signals**;	**bck_en_snr_t**;	**snr_time**;	**sharpness**;	**bck_en_freq**;	**snr_freq**;	**max_amp	min_amp** information on amplitude and signal to noise ratio extracted from the recording with the scikit-maad python library
      