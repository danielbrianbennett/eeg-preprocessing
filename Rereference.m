function [params] = Rereference(params)
% Tested with toolbox version 3.0 and eeglab version 12
if params.isMerged
    params.runsToDo = 1;
end

if params.isEpoched

    for i = 1:params.nEpochDivisions
    
        fprintf('Restarting eeglab... \n');
        close all
        [ALLEEG EEG CURRENTSET ALLCOM] = eeglab;
        fprintf('Done.\n');
        
        for r = 1:params.runsToDo

            if ~params.isMerged
                filename = [params.sbj '_r' num2str(r) '_'  params.epochNames{i} params.saveSuffix];
            else filename = [params.sbj  '_' params.epochNames{i} params.saveSuffix];
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
                filename = [params.sbj '_r' num2str(r) '_'  params.epochNames{i} params.saveSuffix];
            else filename = [params.sbj  '_' params.epochNames{i} params.saveSuffix];
            end

            [ALLEEG EEG CURRENTSET] = pop_newset(ALLEEG, EEG, CURRENTSET,'retrieve',r,'study',0);


            % Reference
            EEG = pop_reref( EEG, params.reference, 'keepref', 'on' );
            EEG = eeg_checkset( EEG );                

            % save run data to disk
            EEG = pop_saveset( EEG, 'filename',filename,'filepath',[params.cleandir params.sbj filesep]);
            EEG = eeg_checkset( EEG );
            eeglab redraw;

        end

    end
  
    else %ie if prior to epoching
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

            % Referencing
            EEG = pop_reref( EEG, params.reference, 'keepref', 'on'  );
            EEG = eeg_checkset( EEG );

            % save run data to disk
            EEG = pop_saveset( EEG, 'filename',filename,'filepath',[params.cleandir params.sbj filesep]);
            EEG = eeg_checkset( EEG );
            eeglab redraw;

        end
end
    
    
if isempty(params.reference)
    text = sprintf('\tData re-referenced to average reference.\n');
elseif numel (params.reference) == 1
    text = sprintf('\tData re-referenced to electrode %s\n', EEG.chanlocs(params.reference).labels);
else 
    text = '\tData re-referenced to average of electrodes ';
    for i = 1:numel(params.reference)
        text = [text EEG.chanlocs(params.reference(i)).labels ', '];
    end
    text = [text '.\n'];
end
    
fid = fopen(sprintf('%spreprocessing_summary_%s.txt', [params.cleandir params.sbj '\'], params.sbj), 'a+');
fprintf(fid, text);
fclose(fid);
end
