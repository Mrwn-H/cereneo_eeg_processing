% Preprocess data following instructions from bemobil_config_script

addpath(genpath("C:\Users\haiou\Documents\Cereneo")); %Add the analysis folder to the path
bemobil_config_script; %Load the script controlling preprocessing parameters
subjects = 1:8; %Subject IDs to be preprocessed
force_recompute = 1; %Forces script to redo preprocessing

rawfilepath = bemobil_config.study_folder;
montage_path = 'C:\Users\haiou\AppData\Roaming\MathWorks\MATLABAdd-Ons\Collections\EEGLAB\plugins\dipfit5.3\standard_BEM\elec\standard_1020.elc'; %Path containing info on electrode placement
prepare_subject(rawfilepath,subjects,montage_path,bemobil_config) %Convert data from .eeg to .set format, add gait events and crop recordings
preprocess_subject(subjects,bemobil_config,force_recompute) %Perform preprocessing