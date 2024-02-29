function [] = prepare_subject(rawfilepath,subjects,montage_path,bemobil_config)
% Change data format, crop data to keep relevant parts and add gait events
% if possible

    for i=1:length(subjects)
        data_path = fullfile(rawfilepath,'2_raw-EEGLAB',['sub-' num2str(subjects(i))]); %Find the path where raw files are stored

        % Check bounds

        recordings = dir(fullfile(data_path,'*.vhdr')); %Load raw recording
        
        %Find all recordings for a given subject
        recordings_name = cell(1,height(recordings));
        for k=1:height(recordings)
            recordings_name{k} = recordings(k).name;
        end
        
        recordings_idxs = [];
        
        %Filter the wanted recordings if specified (i.e
        %bemobil_config.recordings = {'Baseline','FB'})
        if ~isempty(bemobil_config.recordings)
            for k=1:length(bemobil_config.recordings)
                recordings_idxs = [recordings_idxs;find(contains(recordings_name,['_' bemobil_config.recordings{k}]))];
            end
        else
            recordings_idxs = 1:length(recordings);
        end

        % Use pop_loadbv to load BrainVision data
        for j=1:length(recordings_idxs)
            current_idx = recordings_idxs(j);
            EEG = pop_loadbv(data_path, recordings(current_idx).name, [], [], []);
            comments = EEG.comments;
            %Correction if subjects are exported as Sn instead of sub-n
            if contains(comments,'S')
                comments = split(comments,'S');
                EEG.comments = [comments{1} 'sub-' comments{2}];
            end
            EEG = pop_chanedit(EEG,'lookup',montage_path); %Add channel location information
            conditions = split(recordings(current_idx).name,'.'); 
            condition = split(conditions{1},'_');
            condition = condition{2}; %Extract current condition

            if ~strcmp(condition,'standing') %standing baseline has no events and isn't processed here
                % Define the time window to remove
                events = EEG.event;
                events = struct2table(events);
                
                %Change the second event to "Walk Onset"
                walk_onset_idx = find(ismember(events.type,'s1'),2);
                walk_onset_idx = walk_onset_idx(2);
                EEG.event(walk_onset_idx).type = 'Walk Onset';
                
                
                t_start = EEG.times(events(find(ismember(events.type,'s1'),1),:).latency); %Set the first trigger input as the beginning of the recording
                t_end = EEG.times(events(find(ismember(events.type,'s1'),3),:).latency); %Set the third trigger input as the end of the recording
                t_end = t_end(3);
                
                
                EEG = pop_select(EEG, 'time', [t_start/1000 t_end/1000]); %Crop raw data Note: Times are in milisecond and need to be divided by 1000
                EEG = create_events(EEG,rawfilepath); %Add gait events if possible
            end
            
            if ~strcmp(condition,'standing')
                EEG.event = EEG.event(2:end-1);
                [EEG, idxs] = pop_selectevent(EEG,'type',['s1']);
            end
            % Save the resulting EEG structure to a .set file

            pop_saveset(EEG, fullfile(data_path,['sub-' num2str(subjects(i)) '_' condition '_EEG']));
        end
    end
end