function [params] = NotchFilter(params)
% Tested with toolbox version 3.0 and eeglab version 12
fprintf('Restarting eeglab... \n');
close all
[ALLEEG EEG CURRENTSET ALLCOM] = eeglab;
fprintf('Done.\n');

for r = 1:params.runsToDo
    

    if ~params.isMerged
        filename = [params.sbj '_r' num2str(r) params.saveSuffix];
    else filename = [params.sbj params.saveSuffix];
    end


    try
        fprintf('Loading run data...\n')
        EEG = pop_loadset('filename', filename, 'filepath', [params.cleandir params.sbj filesep] );
        [ALLEEG, EEG, CURRENTSET] = eeg_store( ALLEEG, EEG, 0 );
        fprintf('Done.\n')
    catch
        error('Cannot find data file.')
    end

    
end


for r = 1:numel(ALLEEG)
    
    if ~params.isMerged
        filename = [params.sbj '_r' num2str(r) params.saveSuffix];
    else filename = [params.sbj params.saveSuffix];
    end
    
    [ALLEEG EEG CURRENTSET] = pop_newset(ALLEEG, EEG, CURRENTSET,'retrieve',r,'study',0);
    EEG = pop_eegfiltnew(EEG, min(params.notchCutoff), max(params.notchCutoff), [], 1, [], 0);
    EEG = eeg_checkset( EEG );
    eeglab redraw;

    % save run data to disk
    EEG = pop_saveset( EEG, 'filename',filename,'filepath',[params.cleandir params.sbj filesep]);
    EEG = eeg_checkset( EEG );
    eeglab redraw;
    
end
 
fid = fopen(sprintf('%spreprocessing_summary_%s.txt', [params.cleandir params.sbj filesep], params.sbj), 'a+');  
fprintf(fid, '\tData notch filtered between %.0f and %.0fHz.\n', min(params.notchCutoff), max(params.notchCutoff));
fclose(fid);
end
