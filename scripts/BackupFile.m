function BackupFile(params)
% Tested with toolbox version 3.0 and eeglab version 12

name_regexp = '^[a-zA-Z_0-9]+';
name = regexp(params.saveSuffix,'^[a-zA-Z_0-9]+','match');
name = cell2mat(name);
backupSuffix = [name '_backup' '.set'];

if params.isMerged
    
     
    for i = 1:params.nEpochDivisions
    

    fprintf('Restarting eeglab... \n');
    close all
    [ALLEEG EEG CURRENTSET ALLCOM] = eeglab;
    fprintf('Done.\n');

        filename = [params.sbj  '_' params.epochNames{i} params.saveSuffix];

    try
        fprintf('Loading data...\n')
        EEG = pop_loadset('filename', filename, 'filepath', [params.cleandir params.sbj filesep] ); %
        fprintf('Done.\n')
    catch
        error('Cannot find data file.')
    end

    
    savename = [params.sbj '_' params.epochNames{i} backupSuffix];

    % save run data to disk
    EEG = pop_saveset( EEG, 'filename',savename,'filepath',[params.cleandir params.sbj filesep]);
    eeglab redraw;
    
    end
    
    
elseif ~params.isMerged

    for r = 1:params.runsToDo
       
        for i = 1:params.nEpochDivisions

            fprintf('Restarting eeglab... \n');
            close all
            [ALLEEG EEG CURRENTSET ALLCOM] = eeglab;
            fprintf('Done.\n');

            filename = [params.sbj '_r' num2str(r) '_'  params.epochNames{i} params.saveSuffix];

            try
                fprintf('Loading run data...\n')
                EEG = pop_loadset('filename', filename, 'filepath', [params.cleandir params.sbj filesep] ); %
                fprintf('Done.\n')
            catch
                error('Cannot find data file.')
            end

            savename = [params.sbj '_r' num2str(r) '_'  params.epochNames{i} backupSuffix];

            % save run data to disk
            EEG = pop_saveset( EEG, 'filename',savename,'filepath',[params.cleandir params.sbj filesep]);
            eeglab redraw;



        end


        
    end

end

end
