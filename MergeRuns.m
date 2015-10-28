function [params] = MergeRuns(params)
% Tested with toolbox version 3.0 and eeglab version 12


for i = 1:params.nEpochDivisions
    
    fprintf('Restarting eeglab... \n');
    close all
    [ALLEEG EEG CURRENTSET ALLCOM] = eeglab;
    fprintf('Done.\n');

    for r = 1:params.runsToDo
                        
            filename = [params.sbj '_r' num2str(r) '_' params.epochNames{i} params.saveSuffix];

            try
                fprintf('Loading run data...\n')
                EEG = pop_loadset('filename', filename, 'filepath', [params.cleandir params.sbj filesep] );
                [ALLEEG, EEG, CURRENTSET] = eeg_store( ALLEEG, EEG );
                eeglab redraw        
                fprintf('Done.\n')
            catch
                error('Cannot find data file.')
            end
            
    end
    
            savename = [params.sbj '_' params.epochNames{i} params.saveSuffix];
    
           % merge runs
           
           if params.runsToDo > 1 && ~params.isMerged
               EEG = pop_mergeset( ALLEEG, 1:params.runsToDo, 0);
               [ALLEEG, EEG, CURRENTSET] = eeg_store( ALLEEG, EEG );
               EEG.setname = [params.sbj '_epochs_' params.epochNames{i}];
               EEG = eeg_checkset( EEG );
               eeglab redraw
           end
                       
            % save run data to disk
            EEG = pop_saveset( EEG, 'filename',savename,'filepath',[params.cleandir params.sbj filesep]);
            EEG = eeg_checkset( EEG );
            eeglab redraw;
            

end

params.isMerged = 1;


fid = fopen(sprintf('%spreprocessing_summary_%s.txt', [params.cleandir params.sbj filesep], params.sbj), 'a+');      
fprintf(fid, '\tRuns merged into a single file.\n');
fclose(fid);

end
