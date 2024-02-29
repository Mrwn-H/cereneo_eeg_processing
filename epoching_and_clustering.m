%% BeMoBIL Pipeline example for EEG study level creation and IC clustering
%
% Author: Marius Klug, TU Berlin, 2022
%% settings
addpath(genpath("C:\Users\haiou\Documents\Cereneo")); %Add the analysis folder to the path
clear all;
bemobil_config_script;
if ~exist('ALLEEG','var')
    eeglab
end
subjects = 1:8; %Subject IDs to be epoched
conditions = {'Baseline'}; %Conditions of interest
% filepaths
base_filename = 'C:\Users\haiou\Documents\Cereneo\Data\Study';
filepath_singlesubject = fullfile(base_filename,'5_single-subject-EEG-analysis');
filepath_epochs = fullfile(base_filename,'5_single-subject-EEG-analysis','epoched');
filepath_study = fullfile(base_filename,'6_EEG-study');

%% epoching
for subjectIdx = 1:length(subjects)
    for conditionIdx = 1:length(conditions)
        % adapt filepaths!
        inputPath = [filepath_singlesubject '\sub-' num2str(subjects(subjectIdx)) '\'];
        outputPath = [filepath_epochs '\sub-' num2str(subjects(subjectIdx)) '\'];
        
        % Load EEG
        ALLEEG = []; EEG = [];


        EEG = load_EEG(inputPath,conditions{conditionIdx},'preprocessed');
        
        % create actual epochs
        %Here we use Left Heel Strike to create epochs, with each epoch
        %going from [-t1 t2]. 
        %Recommended to set t2 as the length in seconds of the longest gait
        %cycle to analyse
        EEG_epoched = pop_epoch( EEG, 'LHS', [-0.1  1.37], 'newname', 'Stimulus ERP', 'epochinfo', 'yes');
        %EEG_epoched = pop_rmbase( EEG, [-100 0]);

        % clean epochs automatically
        % for this the dataset needs to be epoched again, but on a 12hz highpass filtered dataset, since that removes eye
        % movements, which can easily be cleaned by ICA and do not have to be removed in the epoch-domain
        
        % filter the continuous dataset again
        [ALLEEG, EEG_cleaningfilt, CURRENTSET]  = bemobil_filter( ALLEEG, EEG, CURRENTSET, 12, []);
        
        % create epochs for cleaning 
        EEG_epoched_cleaning = pop_epoch( EEG_cleaningfilt, 'LHS', [-0.1  1.37], 'newname', 'Stimulus ERP', 'epochinfo', 'yes');
        
        %Remove baseline from epoch (period before 0)
        %EEG_epoched_cleaning = pop_rmbase( EEG_epoched_cleaning, [-100 0]); Not used here 
        
        % find indices of bad epochs
        EEG_epoched_cleaning = bemobil_reject_epochs(EEG_epoched_cleaning,0.1,[1 1 1 1],0,0,0,0,1);
        h_rej_1 = gcf;
        
        % clean the actual epoched data set
        EEG_epoched_cleaned = pop_select( EEG_epoched, 'notrial',find(EEG_epoched_cleaning.etc.bemobil_reject_epochs.rejected_epochs));  
          
    
        % save rejection plot and epoched files 
        mkdir(outputPath)
        print(h_rej_1,fullfile(outputPath,['sub-' num2str(subjects(subjectIdx)) '_epoched_cleaning.png']),'-dpng')
        close(h_rej_1)
       
        
        pop_saveset( EEG_epoched_cleaned, 'filename',['sub-' num2str(subjects(subjectIdx)) '_' conditions{conditionIdx} '_epoched.set'],'filepath', outputPath);
    end
end


%% load epoched data

STUDY = []; CURRENTSTUDY = 0; ALLEEG = []; EEG =[]; CURRENTSET=[];

mkdir(filepath_study)
subjects = 1:8;
conditions = {'Baseline'};
for subject = subjects
    for conditionIdx = 1:length(conditions)
        EEG = pop_loadset('filename',['sub-' num2str(subject) '_' conditions{conditionIdx} '_epoched.set'],...
        'filepath',fullfile(filepath_epochs,['sub-' num2str(subject)]));
        [ALLEEG EEG CURRENTSET] = pop_newset(ALLEEG, EEG, 0,'study',0);
    end
end

eeglab redraw

%% create study from all files
commands = cell(length(ALLEEG),1);

for i=1:length(ALLEEG)
    condition = split(ALLEEG(i).filename,'_');
    subject = condition{1};
    condition = condition{2};
    row = {'index', i, 'subject', subject, 'condition', condition}; %Save information for the STUDY variable
    commands{i,1} = row;
end

[STUDY ALLEEG] = std_editset( STUDY, ALLEEG, 'name','baseline','updatedat','on','rmclust','off', ...
    'commands', commands);
[STUDY ALLEEG] = std_checkset(STUDY, ALLEEG);
[ALLEEG EEG CURRENTSET] = pop_newset(ALLEEG, EEG, length(ALLEEG),'retrieve',[1:length(ALLEEG)] ,'study',1); CURRENTSTUDY = 1;
eeglab redraw

%% create component measures 
% 1.5 - 4 min

measurestimer = tic;

[STUDY, ALLEEG] = std_precomp_cereneo(STUDY, ALLEEG, 'components','savetrials','on','allcomps','on','erp','on','erpparams',...
    {'rmbase',[-100 0] },'scalp','on','spec','on','specparams',{'specmode','fft','logtrials','off','recompute','off'}, ...
    'rmicacomps','processica','ersp', 'on', 'erspparams',{'cycles', [1 0.8], 'freqs',[4 120],'nfreqs', 100, 'timesout',0:5:999,'ntimesout', 200, ...
    'recompute','on','scale','abs','alpha',0.05}); %Compute several measures (erps, erds, IC scalp map, ...) to perform clustering of ICs.
%Note: ERDS data is not used for actual clustering, but is computed ahead
%of time for future analysis
eeglab('redraw');

t_measures = toc(measurestimer)/60;

%% build preclustering array
% 5.5 - 14 min

preclusttimer = tic;

clustering_weights = struct('spec',1,'erp',1,'scalp',1,'dipoles',3);
freqrange = [3 25];
timewindow = []; % full time window

[STUDY, ALLEEG, EEG] = bemobil_precluster(STUDY, ALLEEG, EEG, clustering_weights, freqrange, timewindow);

t_preclust = toc(preclusttimer)/60;

%% save study

[STUDY EEG] = pop_savestudy( STUDY, EEG, 'filename','EEG.study','filepath',...
    filepath_study);
CURRENTSTUDY = 1; EEG = ALLEEG; CURRENTSET = [1:length(EEG)];

%% load study

STUDY = []; CURRENTSTUDY = 0; ALLEEG = []; EEG=[]; CURRENTSET=[];
[STUDY ALLEEG] = pop_loadstudy('filename', 'EEG.study', 'filepath',...
    filepath_study);
CURRENTSTUDY = 1; EEG = ALLEEG; CURRENTSET = [1:length(EEG)];

%% Repeated clustering of ICs
% depending on the number of iterations this can take quite some time, but the iterations are saved on the disk and can
% be loaded, so this is used here. feel free to delete them and compute it yourself!

% subjects, 
% ICs/subjects, 
% normalized spread, 
% mean RV, 
% distance from ROI, 
% mahalanobis distance from median of multivariate distribution (put this very high to get the most "normal" solution)
repeated_clustering_weights = [3 -1 -1 -1 -2 -1];

n_clust = 50; % usually having a few less than the number of ICs is a good idea to make sure they all get some entries
outlier_sigma = 3; % to remove ICs that do not fit in a cluster. set to 100 to switch off
force_clustering = 0;
force_multivariate_data = 1;
n_repetitions = 100; %Amount of steps desired for clustering
%n_repetitions= 1000;

%% ROI clustering
ROI_clusters = [struct('x',0,'y',-48,'z',39,'name','PCC'),...   %Parietal cingulate cortex
                struct('x',0,'y',33,'z',16,'name','ACC'),...    %Anterior cingulate cortex
                struct('x',62,'y',-14,'z',30,'name','RPM'),...  %Right primary motor cortex
                struct('x',-36,'y',-19,'z',48,'name','LPM'),... %Left primary motor cortex
                struct('x',-5,'y',-19,'z',66,'name','LSM'),...  %Left sensory motor cortex
                struct('x',6,'y',-40,'z',62,'name','RSM')];     %Right sensory motor cortex
for i=1:length(ROI_clusters)
    ROI_MNI = ROI_clusters(i);
    [STUDY, ALLEEG, EEG] = bemobil_repeated_clustering_and_evaluation(STUDY, ALLEEG, EEG, outlier_sigma, n_clust,...
    n_repetitions,ROI_MNI , repeated_clustering_weights, force_clustering, force_multivariate_data, STUDY.filepath,...
    ['EEG_' ROI_MNI.name], fullfile(STUDY.filepath,'clustering'),[ 'clustering_solutions_' num2str(n_repetitions)],...
    fullfile(STUDY.filepath,'clustering'), ['multivariate_data_' ROI_MNI.name '_' num2str(n_repetitions)]);
    
    STUDY.etc.bemobil.clustering_result.(ROI_MNI.name) = STUDY.etc.bemobil.clustering;
end
%% Save clustered study
[STUDY EEG] = pop_savestudy( STUDY, EEG, 'filename','EEG_clustered.study','filepath',...
    filepath_study);
CURRENTSTUDY = 1; EEG = ALLEEG; CURRENTSET = [1:length(EEG)];

%% Load clustered study

STUDY = []; CURRENTSTUDY = 0; ALLEEG = []; EEG=[]; CURRENTSET=[];
[STUDY ALLEEG] = pop_loadstudy('filename', 'EEG_clustered.study', 'filepath',...
    filepath_study);
CURRENTSTUDY = 1; EEG = ALLEEG; CURRENTSET = [1:length(EEG)];
%% Plot ERSP
clustering_results = STUDY.etc.bemobil.clustering_result;
clusters = fieldnames(clustering_results);
for i=1:length(clusters)
    [STUDY] = std_erspplot_cereneo(STUDY, ALLEEG,'clusters',clustering_results.(clusters{i}).cluster_ROI_index,'caxis',[0.8 1.2]);
end

%% Test ASR manually - Not used
STUDY = []; CURRENTSTUDY = 0; ALLEEG = []; EEG =[]; CURRENTSET=[];
mkdir(filepath_study)

for subject = subjects
    for conditionIdx = 1:length(conditions)
        EEG = pop_loadset('filename',['sub-' num2str(subject) '_' conditions{conditionIdx} '_cleaned_with_ICA.set'],...
        'filepath',fullfile(filepath_singlesubject,['sub-' num2str(subject)]));
        [ALLEEG EEG CURRENTSET] = pop_newset(ALLEEG, EEG, 0,'study',0);
    end
end

eeglab redraw
%%
EEG_clean = clean_artifacts(EEG,'ChannelCriterion','off','LineNoiseCriterion','off');
vis_artifacts(EEG,EEG)
[ALLEEG EEG CURRENTSET] = pop_newset(ALLEEG, EEG_clean, 0,'study',0);
eeglab redraw
