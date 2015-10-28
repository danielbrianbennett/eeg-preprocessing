function [params] = EpochData(params)
% Tested with toolbox version 3.0 and eeglab version 12


nEpochsCreated = zeros(params.runsToDo, params.nEpochDivisions);
      
   
for i = 1:params.nEpochDivisions

    fprintf('Restarting eeglab... \n');
    close all
    [ALLEEG EEG CURRENTSET ALLCOM] = eeglab;
    fprintf('Done.\n');
    
    for r = 1:params.runsToDo

    if ~params.isMerged
        filename = [params.sbj '_r' num2str(r) params.saveSuffix];
        savename = [params.sbj '_r' num2str(r) '_' params.epochNames{i} '_epochs.set'];
    else filename = [params.sbj params.saveSuffix];
        savename = [params.sbj  '_' params.epochNames{i} '_epochs.set'];
    end


    try
        fprintf('Loading run data...\n')
        EEG = pop_loadset('filename', filename, 'filepath', [params.cleandir params.sbj filesep] ); %
        [ALLEEG, EEG, CURRENTSET] = eeg_store( ALLEEG, EEG, 0 );
        fprintf('Done.\n')
    catch
        error('Cannot find data file.')
    end

    end
    
    for r = 1:numel(ALLEEG)
        
    if ~params.isMerged
        filename = [params.sbj '_r' num2str(r) params.saveSuffix];
        savename = [params.sbj '_r' num2str(r) '_' params.epochNames{i} '_epochs.set'];
    else filename = [params.sbj params.saveSuffix];
        savename = [params.sbj  '_' params.epochNames{i} '_epochs.set'];
    end
    
    [ALLEEG EEG CURRENTSET] = pop_newset(ALLEEG, EEG, CURRENTSET,'retrieve',r,'study',0);

        
    % epoch data into trials
    fprintf('Epoching data... \n')
    EEG = pop_epoch( EEG, { params.epochTimeLockEvents{i} }, params.epochTimes{i}, 'newname', [params.sbj '_r' num2str(r) '_' params.epochNames{i}], 'epochinfo', 'yes');
    [ALLEEG EEG CURRENTSET] = pop_newset(ALLEEG, EEG, 1,'gui','off'); 
    EEG = eeg_checkset( EEG );
    eeglab redraw
    fprintf('Done.\n')

    % save dataset
    fprintf('Saving dataset... \n')
    EEG = pop_saveset( EEG, savename, [params.cleandir params.sbj filesep]); % save to disk
    eeglab redraw
    fprintf('Done.\n')

    nEpochsCreated(r, i) = EEG.trials;
    
    end
end

params.saveSuffix = '_epochs.set';
params.isEpoched = 1;

for i = 1:params.nEpochDivisions

    fid = fopen(sprintf('%spreprocessing_summary_%s.txt', [params.cleandir params.sbj filesep], params.sbj), 'a+');     
    if ~isempty(params.epochBaselines{i})  
        fprintf(fid, '\tEpoch Mode %.0f:\n\t\tTime Locking Event: %s\n\t\tEpoch Bounds: From %.0fsec before to %.0f sec after time-locked event\n\t\tEpoch Baseline:%.2f to %.2fms\n', i, abs(params.epochTimeLockEvents{i}), params.epochTimes{i}(1), params.epochTimes{i}(2), params.epochBaselines{i}(1), params.epochBaselines{i}(2));
    else
        fprintf(fid, '\tEpoch Mode %.0f:\n\t\tTime Locking Event: %s\n\t\tEpoch Bounds: From %.0fsec before to %.0f sec after time-locked event\n', i, abs(params.epochTimeLockEvents{i}), params.epochTimes{i}(1), params.epochTimes{i}(2));
    end
        fprintf(fid, '\t\tNumber of Epochs Created:\n');
    for r = 1:params.runsToDo
        fprintf(fid, '\t\t\tRun %.0f: %.0f epochs.\n', r, nEpochsCreated(r,i));            
    end

    fclose(fid);

end

epochSaveName = [params.cleandir params.sbj filesep 'epochinfo.mat'];
save(epochSaveName, 'nEpochsCreated');

end
