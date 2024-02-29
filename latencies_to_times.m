function [t_start,t_end,dt] = latencies_to_times(EEG)
    events = EEG.event;
    events = struct2table(events);
    %events = events(find(ismember(events.type,'s1')),:);
    t_start = EEG.times(events(find(ismember(events.type,'s1'),1),:).latency);
    t_end = EEG.times(events(find(contains(events.type,'LHS_nxt'),1,'last'),:).latency);
    %buffer_latency = events(1,:).latency + 10*500;
    %t_end = EEG.times(events(end,:).latency);
    dt = t_end - t_start;
    
end

