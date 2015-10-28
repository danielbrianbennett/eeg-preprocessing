function [ALLEEG EEG CURRENTSET] = AutoReject(params)
% Tested with toolbox version 3.0 and eeglab version 12


fid = fopen(sprintf('%spreprocessing_summary_%s.txt', [params.cleandir params.sbj filesep], params.sbj), 'a+');

if params.isMerged
    params.runsToDo = 1;
end

for i = 1:params.nEpochDivisions   
    
        fprintf(fid, '\t%.0fmV filter applied. Rejected trial numbers in epoch mode %.0f were:\n', params.autoThreshold, i);

        for r = 1:params.runsToDo


            fprintf('Restarting eeglab... \n');
            close all
            [ALLEEG EEG CURRENTSET ALLCOM] = eeglab;
            fprintf('Done.\n');

            if ~params.isMerged
                filename = [params.sbj '_r' num2str(r) '_'  params.epochNames{i} params.saveSuffix];
            else filename = [params.sbj  '_' params.epochNames{i} params.saveSuffix];
            end


            try
                fprintf('Loading run data...\n')
                EEG = pop_loadset('filename', filename, 'filepath', [params.cleandir params.sbj filesep] ); %
                fprintf('Done.\n')
            catch
                error('Cannot find data file.')
            end

            trialsBefore = EEG.trials;

            EEG = pop_eegthresh(EEG,1,params.dataChannels , params.autoThreshold * -1,params.autoThreshold,params.epochTimes{i}(1),params.epochTimes{i}(2),0,1); % reject trials
            EEG = eeg_checkset( EEG );
            eeglab redraw

            trialsAfter = EEG.trials;
            trialsRemoved = trialsBefore - trialsAfter;
            fprintf(fid, 'Run %.0f: %.0f\n', r, trialsRemoved);

            % save run data to disk
            EEG = pop_saveset( EEG, 'filename',filename,'filepath',[params.cleandir params.sbj filesep]);
            EEG = eeg_checkset( EEG );
            eeglab redraw;

        end
        
end

fclose(fid);
end
