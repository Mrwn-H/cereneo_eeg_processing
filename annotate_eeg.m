function [EEG_annotated] = annotate_eeg(EEG)
    
    eeg_filepath = EEG.filepath;
    file_txt = dir(fullfile(eeg_filepath,'*.txt'));
    cell_txt = struct2cell(file_txt);
    condition = split(EEG.filename,'_');
    condition = erase(condition{2},'.set');
    events_idx = find(contains(cell_txt(1,:), ['_' condition] ));
    events_path = fullfile(eeg_filepath,cell_txt{1,events_idx});
    EEG_annotated = pop_importevent(EEG,'append','yes','event',events_path, ...
        'fields',{'type','latency','duration'},'append','no','skipline',1);
    new_filename = EEG.filename;
    new_filename = split(new_filename,'.');
    new_filename{1} = [new_filename{1} '_annotated'];
    new_filename = [new_filename{1} new_filename{2}];
    %pop_saveset(EEG_annotated,'filename',new_filename,'filepath',eeg_filepath)
    
end