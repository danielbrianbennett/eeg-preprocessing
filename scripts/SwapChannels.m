function [params] = SwapChannels(params)
% Tested with toolbox version 3.0 and eeglab version 12

if ~isempty(params.swapChannels)
    
    fprintf('Restarting eeglab... \n');
    close all
    [ALLEEG EEG CURRENTSET ALLCOM] = eeglab;
    fprintf('Done.\n');
    
    filename = [params.sbj params.saveSuffix];

    try
        fprintf('Loading run data...\n')
        EEG = pop_loadset('filename', filename, 'filepath', [params.cleandir params.sbj filesep] ); %
        fprintf('Done.\n')
    catch
        error('Cannot find data file.')
    end
    
    
    % swap channels
    for i = 1:size(params.swapChannels,1)
        
        % identify channels and cut out their data
        channelALabel = params.swapChannels{i,1};
        channelBLabel = params.swapChannels{i,2};
        channelA = find(strcmpi({EEG.chanlocs.labels},channelALabel));
        channelB = find(strcmpi({EEG.chanlocs.labels},channelBLabel));
        
        if isempty(channelA) || isempty(channelB)
            error('Failed to find the specified channel when swapping. Check your specifications.');
        end
        channelA_data = squeeze(EEG.data(channelA,:,:));
        channelB_data = squeeze(EEG.data(channelB,:,:));
        
        % swap the channels in the EEG structure
        EEG.data(channelA,:,:) = channelB_data;
        EEG.data(channelB,:,:) = channelA_data;
        
        
        text = sprintf('Channel %s was swapped with channel %s.\n',channelALabel,channelBLabel);
        fid = fopen(sprintf('%spreprocessing_summary_%s.txt', [params.cleandir params.sbj filesep], params.sbj), 'a+');
        fprintf(fid, text);
        fclose(fid);
        
        clear channelA channelB channelALabel channelBLabel channelA_data channelB_data

    end

    EEG = eeg_checkset( EEG );
    
    % save run data to disk
    EEG = pop_saveset( EEG, 'filename',filename,'filepath',[params.cleandir params.sbj filesep]);
    EEG = eeg_checkset( EEG );
    eeglab redraw;

end


end
