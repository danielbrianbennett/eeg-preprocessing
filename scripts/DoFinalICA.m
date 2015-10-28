function [params] = DoFinalICA(params)
% Tested with toolbox version 3.0 and eeglab version 12



for i = 1:params.nEpochDivisions
               
            fprintf('Restarting eeglab... \n');
            close all
            [ALLEEG EEG CURRENTSET ALLCOM] = eeglab;
            fprintf('Done.\n');

            filename = [params.sbj  '_' params.epochNames{i} params.saveSuffix];
            savename = [params.sbj  '_' params.epochNames{i} '_ica2.set'];
            

            try
                fprintf('Loading run data...\n')
                EEG = pop_loadset('filename', filename, 'filepath', [params.cleandir params.sbj filesep] ); %
                fprintf('Done.\n')
            catch
                error('Cannot find data file.')
            end
            
            % ICA
            fprintf('Computing ICA... (%s)\n', datestr(now,13))

            HPF = 1;                 % high pass filter for ica training only
            DIM = numel(params.dataChannels) - 1;
            %DIM = EEG.nbchan-1;               % ica dimensionality
            THRES = 4;             % SD cut-off for rejection

            % high pass filter
            EEG = pop_eegfilt( EEG, HPF, 0, [6], [0], 0, 1, 'fir1', 1);
            %             EEG = pop_runica(EEG, 'extended',1,'interupt','on','pca',DIM);
            EEG = pop_runica(EEG, 'extended',1,'interupt','on','pca',DIM,'chanind',params.dataChannels);

            fprintf('...finished ICA. (%s)\n', datestr(now,13))

            TMP.icawinv = EEG.icawinv;
            TMP.icasphere = EEG.icasphere;
            TMP.icaweights = EEG.icaweights;
            TMP.icachansind = EEG.icachansind;

            % apply to dataset

            [ALLEEG EEG CURRENTSET ALLCOM] = eeglab;

            EEG = pop_loadset('filename', filename, 'filepath', [params.cleandir params.sbj filesep]); % save to disk
            [ALLEEG, EEG, CURRENTSET] = eeg_store( ALLEEG, EEG );
            eeglab redraw

            EEG.icawinv = TMP.icawinv;
            EEG.icasphere = TMP.icasphere;
            EEG.icaweights = TMP.icaweights;
            EEG.icachansind = TMP.icachansind;

            clear TMP;

            % save run data to disk
            EEG = pop_saveset( EEG, 'filename',savename,'filepath',[params.cleandir params.sbj filesep]);
            EEG = eeg_checkset( EEG );
            eeglab redraw;

end
            params.saveSuffix = '_ica2.set';
            
fid = fopen(sprintf('%spreprocessing_summary_%s.txt', [params.cleandir params.sbj filesep], params.sbj), 'a+');      
fprintf(fid, '\tSecond ICA conducted.\n');
fclose(fid);

end
