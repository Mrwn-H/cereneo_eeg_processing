function [ersp] = plot_study_ersp(STUDY,cluster_id,ALLEEG,filepath_singlesubject)

current_cluster = STUDY.cluster(cluster_id);
comps = current_cluster.comps;
sets = current_cluster.sets;
for i=1:length(ALLEEG)
    comp = comps(i);
    set = sets(i);
    current_eeg = ALLEEG(set);
    subject_info = split(current_eeg.filename,'_');
    subject_id = subject_info{1};
    subject_cond = subject_info{2};
    baseline_eeg = pop_loadset('filename',[subject_id '_' subject_cond '_preprocessed_and_ICA.set'],...
            'filepath',fullfile(filepath_singlesubject,subject_id));
    walk_idx = find(strcmp({baseline_eeg.event.type},'Walk Onset'));
    walk_latency = baseline_eeg.event(walk_idx).latency;
    baseline_ica = baseline_eeg.icaact(:,1:walk_latency);
    RESPONSEtime = [0 1500];
    Response_timelhs_nxt = [100,1500];
    LHS_events = eeg_getepochevent(current_eeg,{'LHS'},RESPONSEtime, 'latency');
    RTO_events = eeg_getepochevent(current_eeg ,{'RTO'},RESPONSEtime, 'latency');
    RHS_events = eeg_getepochevent(current_eeg,{'RHS'},RESPONSEtime, 'latency');
    LTO_events = eeg_getepochevent(current_eeg,{'LTO'},RESPONSEtime, 'latency');
    LHS_nxt_events = eeg_getepochevent(current_eeg , {'LHS_nxt'}, Response_timelhs_nxt, 'latency');
    RT_LAT = [RTO_events',RHS_events' LTO_events' LHS_nxt_events'];
    new_LAT = [100 500 600, 1000];%% generate matrix with rows equal trials and columns equal 0 and RT latencies
    
    [ersp_baseline, itc, powbase_baseline, times, freqs_baseline, eboot, pboot, tfr_baseline]=newtimef( baseline_ica(comp,:),width(baseline_ica),[5000 10000], ...
        current_eeg.srate, 0,'cycles', [1 0.4], 'freqs',[4 150],'plotitc','off','plotmean','off','plotersp','off','baseline',NaN,'nfreqs',100,'plotphasesign','off','scale','abs');
    figure;
    title(['Subject: ' subject_id ', condition: ' subject_cond ', component: ' num2str(comp)]);
    [ersp, itc, powbase, times, freqs, eboot, pboot, tfdata] = newtimef(current_eeg.icaact(comp,:,:), current_eeg.pnts, ...
        [current_eeg.xmin current_eeg.xmax]*1000,  current_eeg.srate,[1 0.4],...
        'freqs',[4 150],'timesout',0:5:999,...
        'timewarp', RT_LAT,'timewarpms',new_LAT,...
         'plotitc', 'off','nfreqs',100,'scale','abs'); %'powbase',powbase_baseline
end
end