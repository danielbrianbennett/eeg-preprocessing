function [params] = InterpolateChannels(params)
% Tested with toolbox version 3.0 and eeglab version 12

for r = 1:params.runsToDo
    
    if ~isempty(params.interpolateChannels{r})
    
        for i = 1:params.nEpochDivisions
            
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


            % interpolate missing channels
            channelList = params.interpolateChannels{r};
            channelIndices = [];
            for ii = 1:numel(channelList)
                channelName = channelList{ii};
                index = find(strcmpi({EEG.chanlocs.labels}, channelName));
                if ~isempty(index)
                    channelIndices(end+1) = index;
                end
            end
            
            EEG = eeg_interp(EEG, channelIndices, 'spherical');
            EEG = eeg_checkset( EEG );

            % save run data to disk
            EEG = pop_saveset( EEG, 'filename',filename,'filepath',[params.cleandir params.sbj filesep]);
            EEG = eeg_checkset( EEG );
            eeglab redraw;
        end
        
        if numel (params.interpolateChannels{r}) == 1
            text = sprintf('\tElectrode %s was interpolated in run %.0f.\n', params.interpolateChannels{r}{1}, r);
        else 
            text = '\tElectrodes ';
            for ii = 1:numel(params.interpolateChannels{r})
                text = [text params.interpolateChannels{r}{ii} ' '];
            end
            text = sprintf('%s were interpolated in run %.0f.\n', text, r);
            
        end

        fid = fopen(sprintf('%spreprocessing_summary_%s.txt', [params.cleandir params.sbj filesep], params.sbj), 'a+');
        fprintf(fid, text);
        fclose(fid);
    end

end

end
