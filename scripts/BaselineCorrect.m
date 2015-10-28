function BaselineCorrect(params)
% Tested with toolbox version 3.0 and eeglab version 12

if params.isMerged
    
     
    for i = 1:params.nEpochDivisions
    
    if ~isempty(params.epochBaselines{i})

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

    % baseline correction
    fprintf('Applying baseline correction... \n')
    EEG = pop_rmbase( EEG, params.epochBaselines{i}); % remove baseline
    EEG = eeg_checkset( EEG );
    eeglab redraw
    fprintf('Done.\n')


    % save run data to disk
    EEG = pop_saveset( EEG, 'filename',filename,'filepath',[params.cleandir params.sbj filesep]);
    eeglab redraw;

    fid = fopen(sprintf('%spreprocessing_summary_%s.txt', [params.cleandir params.sbj filesep], params.sbj), 'a+');
    fprintf(fid, '\tData baseline corrected on interval[%.0f, %.0f].\n', params.epochBaselines{i}(1), params.epochBaselines{i}(2));
    fclose(fid);

    else
        error('Baseline correction was requested, but no baseline time points were provided. Check your config file.');
    end
    
    end
    
    
elseif ~params.isMerged

    for r = 1:params.runsToDo
       
    for i = 1:params.nEpochDivisions
        
        if ~isempty(params.epochBaselines{i})

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
        
        % baseline correction
        fprintf('Applying baseline correction... \n')
        EEG = pop_rmbase( EEG, params.epochBaselines{i}); % remove baseline
        EEG = eeg_checkset( EEG );
        eeglab redraw
        fprintf('Done.\n')
        

        % save run data to disk
        EEG = pop_saveset( EEG, 'filename',filename,'filepath',[params.cleandir params.sbj filesep]);
        eeglab redraw;
        
        fid = fopen(sprintf('%spreprocessing_summary_%s.txt', [params.cleandir params.sbj filesep], params.sbj), 'a+');
        fprintf(fid, '\tData baseline corrected on interval[%.0f, %.0f].\n', params.epochBaselines{i}(1), params.epochBaselines{i}(2));
        fclose(fid);
        
        else
            error('Baseline correction was requested, but no baseline time points were provided. Check your config file.');
        end
        
    end
    
        
        
    end

        fid = fopen(sprintf('%spreprocessing_summary_%s.txt', [params.cleandir params.sbj filesep], params.sbj), 'a+');
        fprintf(fid, '\tData baseline corrected on interval[%.0f, %.0f].\n', params.epochBaselines{i}(1), params.epochBaselines{i}(2));
        fclose(fid);
    
end

end
