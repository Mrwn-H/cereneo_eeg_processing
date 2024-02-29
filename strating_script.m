studyDataFolder = 'C:\Users\haiou\Documents\Cereneo\Data\Lea';
config = struct();
config.bids_target_folder = studyDataFolder;
config.task = 'walking';
config.subject = 0;
config.session = 'walk';
config.resample_freq = 500;
config.filename = fullfile(studyDataFolder,'\Lea_Chabrowsky_2022-06-07_00-26-12.eeg');
config.set_folder = fullfile(studyDataFolder,'\raw_EEGLAB');
config.session_names{1,1} = 'walk';
bemobil_bids2set(config);
%%
% Specify the file path to your BrainVision data
data_path = 'C:\Users\haiou\Documents\Cereneo\Data\Lea';

% Load BrainVision data into FieldTrip
cfg = [];
cfg.dataset = 'C:\Users\haiou\Documents\Cereneo\Data\Lea\Lea_Chabrowsky_2022-06-07_00-26-12.vhdr';  % Provide the path to your .vhdr file
raw_data = ft_preprocessing(cfg);

% Define BIDS parameters
bids_root = 'C:\Users\haiou\Documents\Cereneo\Data\Lea\BIDS';
subject_id = '01';
session_id = '01';
task = 'walk';
run = '01';

% Create BIDS folder structure
bids_folder = fullfile(bids_root, ['sub-' subject_id], ['ses-' session_id], 'eeg');
mkdir(bids_folder);

% Copy data files to BIDS folder
copyfile(fullfile(data_path, 'Lea_Chabrowsky_2022-06-07_00-26-12.vhdr'), bids_folder);
copyfile(fullfile(data_path, 'Lea_Chabrowsky_2022-06-07_00-26-12.vmrk'), bids_folder);
copyfile(fullfile(data_path, 'Lea_Chabrowsky_2022-06-07_00-26-12.eeg'), bids_folder);

%% Turn .eeg into .set
data_path = 'C:\Users\haiou\Documents\Cereneo\Data\2_raw-EEGLAB\sub-4';

subjects = ["S4_fbroad2.vhdr"];
condition = {'walk','stand'};
% Use pop_loadbv to load BrainVision data
for i=1:length(subjects)
    EEG = pop_loadbv(data_path, subjects(i), [], [], []);
    % Define the time window to remove
    start_time = 10000;  % Replace with the start time of the window to remove (in milliseconds)
    end_time = EEG.times(end);    % Replace with the end time of the window to remove (in milliseconds)
    
    % Create a logical index for the time points to keep
    time_index_to_keep = EEG.times < start_time | EEG.times > end_time;
    
    % Use pop_select to create a new dataset without the specified time window
    EEG = pop_select(EEG, 'nopoint', find(time_index_to_keep));
    % Save the resulting EEG structure to a .set file
    pop_saveset(EEG, fullfile(data_path,['sub-4_' condition{i} '_EEG']));
end
%%
% Load EEG data into EEGLAB
EEG = pop_loadset(fullfile(data_path,'sub-4_walk_EEG.set'));
electrode_file = 'C:\Users\haiou\AppData\Roaming\MathWorks\MATLABAdd-Ons\Collections\EEGLAB\plugins\dipfit5.3\standard_BEM\elec\standard_1005.elc';
EEG = pop_chanedit(EEG);
% Extract channel names
channel_names = {EEG.chanlocs.labels};

% Extract channel locations
channel_locations = [EEG.chanlocs.X; EEG.chanlocs.Y; EEG.chanlocs.Z]';

elec_info = readlocs(electrode_file, 'filetype', 'autodetect');
disp(['Number of channels in electrode file: ' num2str(length(elec_info))]);

% Display channel labels in EEG structure
disp(['Channel labels in EEG structure: ']);
disp({EEG.chanlocs.labels});

% Display channel labels in electrode file
disp(['Channel labels in electrode file: ']);
disp({elec_info.labels});
pop_saveset(EEG,fullfile(data_path,['sub-4_' condition{i} '_chan_EEG']));

%%
csv_file = 'C:\Users\haiou\Documents\Cereneo\Data\montage_perfect.csv';
format = {'labels', 'X', 'Y', 'Z'};
for i=1:64
   EEG.chanlocs(i).labels = upper(EEG.chanlocs(i).labels);
end
EEG = pop_chanedit(EEG, 'load', {csv_file, 'format', format});

%% bemobil trial
bemobil_config_script;
subjects = [4];
force_recompute = 0;
for subject = subjects
    
    % prepare filepaths and check if already done
    
	disp(['Subject #' num2str(subject)]);
    
	STUDY = []; CURRENTSTUDY = 0; ALLEEG = [];  CURRENTSET=[]; EEG=[]; EEG_interp_avref = []; EEG_single_subject_final = [];
	
	input_filepath = [bemobil_config.study_folder bemobil_config.raw_EEGLAB_data_folder bemobil_config.filename_prefix num2str(subject)];
	output_filepath = [bemobil_config.study_folder bemobil_config.single_subject_analysis_folder bemobil_config.filename_prefix num2str(subject)];
	
	try
		% load completely processed file
		EEG_single_subject_final = pop_loadset('filename', [ bemobil_config.filename_prefix num2str(subject)...
			'_' erase(bemobil_config.preprocessed_and_ICA_filename,'.set') '_filtered.set'], 'filepath', output_filepath);
    catch
        disp('...failed. Computing now.')
	end
	
	if ~force_recompute && exist('EEG_single_subject_final','var') && ~isempty(EEG_single_subject_final)
		clear EEG_single_subject_final
		disp('Subject is completely preprocessed already.')
		continue
    end
	
	% load data that is provided by the BIDS importer
    % make sure the data is stored in double precision, large datafiles are supported, and no memory mapped objects are
    % used but data is processed locally
	try 
        pop_editoptions( 'option_saveversion6', 0, 'option_single', 0, 'option_memmapdata', 0);
    catch
        warning('Could NOT edit EEGLAB memory options!!'); 
    end
    
    % load files that were created from xdf to BIDS to EEGLAB
    EEG = pop_loadset('filename',[ bemobil_config.filename_prefix num2str(subject) '_' bemobil_config.datatype '_EEG.set' ],'filepath',input_filepath);
    
    % individual EEG processing to remove non-exp segments
    
    allevents = {EEG.event.type}';

    startevents = {EEG.event(find(~cellfun(@isempty,strfind(allevents,'START')) & cellfun(@isempty,strfind(allevents,'TES')))).type}';
    startlatencies = [EEG.event(find(~cellfun(@isempty,strfind(allevents,'START')) & cellfun(@isempty,strfind(allevents,'TES')))).latency]';
    endevents = {EEG.event(find(~cellfun(@isempty,strfind(allevents,'END')) & cellfun(@isempty,strfind(allevents,'test')))).type}';
    endlatencies = [EEG.event(find(~cellfun(@isempty,strfind(allevents,'END')) & cellfun(@isempty,strfind(allevents,'test')))).latency]';

    switch subject 
        case 66
            startlatencies = startlatencies([1:7 9:end]);
            startevents = startevents([1:7 9:end]);
        case 76 % this subject had some issues in the first baseline
            startevents = startevents([2: 9 12:end]);
            startlatencies = startlatencies([2: 9 12:end]);
            endevents = endevents([2: 9 12:end]);
            endlatencies = endlatencies([2: 9 12:end]);
    end

    t = table(startevents,...
    startlatencies,...
    endlatencies,...
    endevents,...
    endlatencies - startlatencies);

    latencies = [[1; endlatencies+EEG.srate] [startlatencies-EEG.srate; EEG.pnts]]; % remove segments but leave a buffer of 1 sec before and after the events for timefreq analysis

    % filter for plot
    EEG_plot = pop_eegfiltnew(EEG, 'locutoff',0.5,'plotfreqz',0);
    
    % plot
    fig1 = figure; set(gcf,'Color','w','InvertHardCopy','off', 'units','normalized','outerposition',[0 0 1 1])

    % basic chan reject for plot
    chanmaxes = max(EEG_plot.data,[],2);
    EEG_plot = pop_select( EEG_plot, 'nochannel',find(chanmaxes>median(chanmaxes)+1.4826 * 3* mad(chanmaxes)));
    chanmins = min(EEG_plot.data,[],2);
    EEG_plot = pop_select( EEG_plot, 'nochannel',find(chanmins<median(chanmins)-1.4826 * 3* mad(chanmins)));
    
    plot(EEG_plot.data' + linspace(0,20000,EEG_plot.nbchan), 'color', [78 165 216]/255)
    xlim([0 EEG.pnts])
    ylim([-1000 21000])
    
    hold on
    
    % plot lines for valid times
    
    for i = 1:size_eeg(latencies,1)
        plot([latencies(i,1) latencies(i,1)],[-1000 21000],'r')
        plot([latencies(i,2) latencies(i,2)],[-1000 21000],'g')
    end
    
    % save plot
    print(gcf,fullfile(input_filepath,[bemobil_config.filename_prefix num2str(subject) '_' erase(bemobil_config.merged_filename,'.set') '_raw-full.png']),'-dpng')
    close
    
    %EEG = eeg_eegrej( EEG, latencies);
    
    % processing wrappers for basic stuff and AMICA
    
    % do basic preprocessing, line noise removal, and channel interpolation
	[ALLEEG, EEG_preprocessed, CURRENTSET] = bemobil_process_all_EEG_preprocessing(subject, bemobil_config, ALLEEG, EEG, CURRENTSET, force_recompute);

    % start the processing pipeline for AMICA
	bemobil_process_all_AMICA(ALLEEG, EEG_preprocessed, CURRENTSET, subject, bemobil_config, force_recompute);

end
%
subjects
subject

bemobil_copy_plots_in_one(bemobil_config)

disp('PROCESSING DONE! YOU CAN CLOSE THE WINDOW NOW!')
%%
%% Turn .eeg into .set
%% Custome download
data_path = 'C:\Users\haiou\Documents\Cereneo\Data\5_single-subject-EEG-analysis';
subject = 'sub-4';
recording = 'sub-4_cleaned_with_ICA.set';
EEG = pop_loadset(fullfile(data_path,subject,recording));
ICA_sources = EEG.icaact;
save(fullfile(data_path,subject,[subject '_ICA_sources.mat']),'ICA_sources')