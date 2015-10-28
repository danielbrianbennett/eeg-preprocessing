function [params] = RemoveBlinks(params)
% Tested with toolbox version 3.0 and eeglab version 12


fid = fopen(sprintf('%spreprocessing_summary_%s.txt', [params.cleandir params.sbj filesep], params.sbj), 'a+');       

if params.isMerged
    params.runsToDo = 1;
end

for i = 1:params.nEpochDivisions
    
    fprintf(fid, '\tBlink Component(s) Removed For Epoch Mode %.0f: ', i);

    for r = 1:params.runsToDo
        
        if params.runsToDo > 1
            fprintf(fid, '\n\t\tRun %.0f: ', r);
        end
        
            close all
            [ALLEEG EEG CURRENTSET ALLCOM] = eeglab;
            fprintf('Done.\n');

            if ~params.isMerged
                filename = [params.sbj '_r' num2str(r) '_' params.epochNames{i} params.saveSuffix];
                savename = [params.sbj '_r' num2str(r) '_' params.epochNames{i} '_stage3.set'];
            else filename = [params.sbj  '_' params.epochNames{i} params.saveSuffix];
                savename = [params.sbj '_' params.epochNames{i} '_stage3.set'];
            end
            
            

            try
                EEG = pop_loadset('filename', filename, 'filepath', [params.cleandir params.sbj filesep] ); %
            catch
                error('Cannot find data file.')
            end
            
            % Display components
            pop_topoplot(EEG,0, [1:params.nComponentsPlotted] ,[params.sbj ' epochs ICA'],[8 9] ,0,'electrodes','off'); % plot components
            EEG.blink = input('Enter eye blink component indices: '); % ask for number of eye blink component
            EEG = pop_subcomp( EEG, [EEG.blink], 0); % remove eye blink component
            
            % save run data to disk
            EEG = pop_saveset( EEG, 'filename',savename,'filepath',[params.cleandir params.sbj filesep]);
            EEG = eeg_checkset( EEG );
            eeglab redraw;
            
            for ii = 1:numel(EEG.blink)
                fprintf(fid, '%.0f ', EEG.blink(ii));
            end
            

    end
fprintf(fid, '\n');
end


fclose(fid);


params.saveSuffix = '_stage3.set';

end
