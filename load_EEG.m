function [EEG] = load_EEG(eeg_filepath,condition,type)

    eeg_files = dir(fullfile(eeg_filepath,'*.set'));
    eeg_files_cell = struct2cell(eeg_files);
    recording_idx = find(contains(eeg_files_cell(1,:), ['_' condition])&contains(eeg_files_cell(1,:), type));
    EEG = pop_loadset('filename',eeg_files_cell{1,recording_idx},'filepath',eeg_filepath);
    
end