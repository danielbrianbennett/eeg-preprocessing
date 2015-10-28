function [params] = SplitRuns(params)
% Tested with toolbox version 3.0 and eeglab version 12

%% Load in the data using information from the params structure
fprintf('Restarting eeglab... \n');
[ALLEEG EEG CURRENTSET ALLCOM] = eeglab;
fprintf('Done.\n');

filename = [params.sbj params.saveSuffix];

try
    fprintf('Loading run data...\n')
    EEG = pop_loadset('filename', filename, 'filepath', [params.cleandir params.sbj filesep] ); %
   	ALLEEG = EEG;
    fprintf('Done.\n')
catch
    error('Cannot find data file.')
end


% find run onsets
allEvents = {EEG.event.type};

for i = 1:length(allEvents)
    allEvents{i} = num2str(allEvents{i});
end

runOnsetTriggers = strcmp(allEvents,params.runOnsetTrigger);
onsetIndex = find( runOnsetTriggers );
runEndTriggers = strcmp(allEvents,params.runEndTrigger);
endIndex = find(runEndTriggers);
nRunsFound = numel(onsetIndex);
fprintf('Found %d run onset triggers.\n',nRunsFound);

% check how many runs were found and start in the corresponding place
if nRunsFound == params.nRuns
    whichRuns = 1:nRunsFound;
elseif nRunsFound > params.nRuns
    whichRuns = params.whichRuns;
else error('Too few run onset triggers found!');
end
    
% split file into runs
run = 1;
for r = whichRuns
    
    fprintf('Extracting data for run %d...\n',run);
    
    params.saveSuffix = '_stage1.set';
    savename = [params.sbj '_r' num2str(run) params.saveSuffix];
    

    
    % find beginning and end of run

    runStart = EEG.event(onsetIndex(r)).latency / EEG.srate - 2;
    
    if isempty(endIndex)
        if r < whichRuns(end)
            runEnd = EEG.event(onsetIndex(r+1)-1).latency / EEG.srate;
        else runEnd = EEG.event(end).latency / EEG.srate;
        end
    else
        if r < whichRuns(end)
        runEnd = EEG.event(endIndex(r)).latency / EEG.srate;
        else runEnd = EEG.event(end).latency / EEG.srate;
        end
    end
    
    % extract run from continuous dataset.
    EEG = pop_select( EEG,'time',[runStart runEnd]);
    [ALLEEG EEG index] = eeg_store(ALLEEG, EEG);
    EEG = eeg_checkset( EEG ); 
    eeglab redraw;    

    % save run data to disk
    EEG = pop_saveset( EEG, 'filename',savename,'filepath',[params.cleandir params.sbj filesep]);
    EEG = eeg_checkset( EEG );
    eeglab redraw;
    
    fprintf('Created new dataset with %d points (%1.1f seconds).\n',EEG.pnts,EEG.xmax);

    
        
    EEG = eeg_retrieve( ALLEEG, 1 );
    eeglab redraw;
    
    
    run = run + 1;
    
end

params.isMerged = 0;

fid = fopen(sprintf('%spreprocessing_summary_%s.txt', [params.cleandir params.sbj filesep], params.sbj), 'a+');     
fprintf(fid, '\tData split into %.0f runs.\n', numel(whichRuns));
fclose(fid);
end
