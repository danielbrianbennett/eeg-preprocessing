function [params] = RunCSD(params)
% needs the CSD Toolbox (http://psychophysiology.cpmc.columbia.edu/software/CSDtoolbox/tutorial.html)
% montage taken from 10-5-System_Mastoids_EGI129.csd (CSD Toolbox)
% (http://psychophysiology.cpmc.columbia.edu/software/CSDtoolbox/10-5-System_Mastoids_EGI129.csd)
% requires labels stored in "labels.txt"
% Tested with toolbox version 3.0 and eeglab version 12


for i = 1:params.nEpochDivisions

    fprintf('Restarting eeglab... \n');
    close all
    [ALLEEG EEG CURRENTSET ALLCOM] = eeglab;
    fprintf('Done.\n');

    filename = [params.sbj  '_' params.epochNames{i} params.saveSuffix];
    savename = [params.sbj  '_' params.epochNames{i} '_csd.set'];
        
    try
        fprintf('Loading run data...\n')
        EEG = pop_loadset('filename', filename, 'filepath', [params.cleandir params.sbj filesep] ); %
        fprintf('Done.\n')
    catch
        error('Cannot find data file.')
    end
    
    %perform csd analysis
    labels_file = [params.csdLabelsPath params.csdLabelsFile];
    labels = textread(labels_file,'%s');
    M = ExtractMontage(params.csdMontage,labels);
    % MapMontage(M) %  to view the montage
    [G,H] = GetGH(M);

    full_data=EEG.data;
    all_data=full_data(params.dataChannels,:,:);
    sz=size(all_data);
    all_csd=zeros(sz);

    for i=1:(sz(1,3))
        tmp_data=all_data(:,:,i);
        csd_temp = CSD (tmp_data, G, H);
        all_csd(:,:,i)=csd_temp;
        clear csd_temp;
        clear tmp_data;
        fprintf('Finished epoch %d \n',i)
    end

    EEG.data(params.dataChannels,:,:)=all_csd;
    EEG = eeg_checkset( EEG );
    eeglab redraw
    
    % save data to disk
    EEG = pop_saveset( EEG, 'filename',savename,'filepath',[params.cleandir params.sbj filesep]);
    EEG = eeg_checkset( EEG );
    eeglab redraw;
    
    
end
params.saveSuffix = '_csd.set';


fid = fopen(sprintf('%spreprocessing_summary_%s.txt', [params.cleandir params.sbj filesep], params.sbj), 'a+');
fprintf(fid, '\tCSD performed using montage file %s%s\n', params.csdLabelsPath, params.csdMontage);
fclose(fid);
    
end

