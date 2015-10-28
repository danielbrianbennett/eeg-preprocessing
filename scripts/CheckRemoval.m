function CheckRemoval(params)
% Tested with toolbox version 3.0 and eeglab version 12


epochLoadName = [params.cleandir params.sbj '\epochinfo.mat'];
load(epochLoadName, 'nEpochsCreated');

newEpochsCreated = zeros(params.runsToDo, params.nEpochDivisions);
fid = fopen(sprintf('%spreprocessing_summary_%s.txt', [params.cleandir params.sbj filesep], params.sbj), 'a+');       

if ~params.isMerged

    for i = 1:params.nEpochDivisions


        fprintf(fid, '\tNumber of Epochs Manually Removed for Mode %.0f:\n', i);
        close all
        [ALLEEG EEG CURRENTSET ALLCOM] = eeglab;
        for r = 1:params.runsToDo
   
            filename = [params.sbj '_r' num2str(r) '_'  params.epochNames{i} params.saveSuffix];          

            try
                EEG = pop_loadset('filename', filename, 'filepath', [params.cleandir params.sbj filesep] ); %
                [ALLEEG, EEG, CURRENTSET] = eeg_store( ALLEEG, EEG, 0 );

            catch
                error('Cannot find data file.')
            end
            
        end
        
        for r = 1:numel(ALLEEG)
                
            [ALLEEG EEG CURRENTSET] = pop_newset(ALLEEG, EEG, CURRENTSET,'retrieve',r,'study',0);


            nAfter = EEG.trials;
            nBefore = nEpochsCreated(r,i);       
            nRemoved = nBefore- nAfter;

            fprintf(fid, '\t\tRun %.0f: %.0f\n', r, nRemoved);

            newEpochsCreated(r, i) = EEG.trials;

        end


    end

else 
    
    for i = 1:params.nEpochDivisions


        totalNEpochs = sum(nEpochsCreated(:,i));
        
        fprintf(fid, '\tNumber of Epochs Manually Removed for Mode %.0f:', i);

        close all
        [ALLEEG EEG CURRENTSET ALLCOM] = eeglab;
        fprintf('Done.\n');


        filename = [params.sbj  '_' params.epochNames{i} params.saveSuffix];
        

        try
            EEG = pop_loadset('filename', filename, 'filepath', [params.cleandir params.sbj filesep] ); %
        catch
            error('Cannot find data file.')
        end

        nAfter = EEG.trials;
        nBefore = totalNEpochs;       
        nRemoved = nBefore- nAfter;
        
%         fprintf(fid, '%.0f\n', nRemoved);

        newEpochsCreated(1, i) = EEG.trials;

    end    
    
fclose(fid);
nEpochsCreated = newEpochsCreated;
epochSaveName = [params.cleandir params.sbj filesep 'epochinfo.mat'];
save(epochSaveName, 'nEpochsCreated');

end
