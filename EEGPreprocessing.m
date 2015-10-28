function EEGPreprocessing(filename, switchProfile, configFile)
 %EEGPreprocessing.m is the master script to preprocess a raw eeg file (usually .edf or .cnt)
% This is version 3.0, tested with EEGLAB version 12
%
% Usage: EEGPreprocessing(filename, switchProfile, configFile), where
%       [string] filename is the file to be processed (e.g. 'p00324.edf')
%       [string] switchProfile is the portion of preprocessing to do.
%           Options are 'stage1', 'stage2', 'finalICA', or 'custom'
%       [function handle] configFile is a function handle specifying the
%           config file which will set the parameters and preprocessing
%           pipeline switches (e.g. @dandec_cedrus_config). Refer to 
%           dandec_cedrus_config to see the structure this file must have.
%
% Last edited by DB 21/7/2014

%% Load paramaters and processing pipeline switches
[switches, params] = feval(configFile, switchProfile);

%% Extract subject and file format information from input filename
sbj_regexp = '^[a-zA-Z_0-9]+';
fileformat_regexp = '[a-zA-Z]+$';
sbj = regexp(filename,sbj_regexp,'match'); 
params.sbj = cell2mat(sbj);
fileformat = regexp(filename,fileformat_regexp,'match');  
params.fileformat = cell2mat(fileformat);
params.filename = filename;

%% Work Out Number of Runs To Do
if params.isMerged
    params.runsToDo = 1;
elseif ~isempty(params.whichRuns)
    params.runsToDo = numel(params.whichRuns);
else    
    params.runsToDo = params.nRuns;
end

%% Create Output Directory
sbjDir = [params.cleandir params.sbj filesep];

if ~isdir(sbjDir)
    mkdir(sbjDir)
end

%% Ask for information about bad channels - if relevant
if params.askForInput
   
        fprintf('Asking user for information (if relevant)... \n');
        params = AskForInput(params,switches);
        fprintf('Done.\n');
    
end

%% Load dataset - beginning of stage 1
if switches.loadDataset
    
        fprintf('Reading EEG file... \n')

        [ALLEEG EEG CURRENTSET ALLCOM] = eeglab;
        setnumber = 1;

        % Load file with a function that varies according to the input file format
        if strcmp(params.fileformat, 'edf')
            EEG = pop_biosig( [params.rawdir params.sbj filesep filename], 'ref',params.inRef,'blockepoch','off');
        elseif strcmp(params.fileformat, 'cnt');
            EEG = pop_loadcnt([params.rawdir params.sbj filesep filename], 'dataformat', 'int32', 'keystroke', 'on');
        end

        [ALLEEG EEG params.completeSet] = pop_newset(ALLEEG, EEG, setnumber,'setname',params.sbj,'gui','off');
        CURRENTSET = params.completeSet;
        EEG = eeg_checkset( EEG );

        params.runsToDo = 1;
        savename = [params.sbj params.saveSuffix];
        pop_saveset( EEG, 'filename',savename,'filepath',[params.cleandir params.sbj filesep]);
        fprintf('Done.\n')
          
        fid = fopen(sprintf('%spreprocessing_summary_%s.txt', [params.cleandir params.sbj filesep], params.sbj), 'a+');         
        fprintf(fid, '\nNEW PREPROCESSING SESSION %s:\n\tData read in .%s format.\n', datestr(now, 'dd/mm/yyyy'), params.fileformat);
        fclose(fid);
        
end

%% Swap Channels
if switches.swapChannels
    
        fprintf('Swapping data channels... \n');
        SwapChannels(params);
        fprintf('Done.\n');
    
end

%% Recode events (including deletions, creation of new events, etc.)
if switches.recodeEvents
    
        fprintf('Recoding events... \n');
        params.eventRecodingScript(params)
        fprintf('Done.\n');
        
        fid = fopen(sprintf('%spreprocessing_summary_%s.txt', [params.cleandir params.sbj filesep], params.sbj), 'a+');   
        fprintf(fid, '\tEvents recoded using the function %s\n', func2str(params.eventRecodingScript));
        fclose(fid);
    
end

%% Split EEG runs
if switches.splitRuns
       
       params.runsToDo = params.nRuns;
       fprintf('Splitting EEG file into runs... \n') 
       [params] = SplitRuns(params);
       fprintf('Done.\n')    
          
end

%% Delete unused channels
if switches.deleteChannels

        fprintf('Deleting unused channels... \n');
        DeleteChannels(params);
        fprintf('Done.\n');

end

%% High-pass filter
if switches.highpassFilter

        fprintf('High-pass filtering... \n');
        Highpass(params);
        fprintf('Done.\n');

end

%% Low-pass filter
if switches.lowpassFilter

        fprintf('Low-pass filtering... \n');
        Lowpass(params);
        fprintf('Done.\n');

end

%% Notch filter
if switches.notchFilter
    
        fprintf('Notch filtering... \n');
        NotchFilter(params);
        fprintf('Done.\n');
    
end
%% Rereference
if switches.reref

        fprintf('Rereferencing to average reference... \n');
        Rereference(params);
        fprintf('Done.\n');

end


%% Add channel locations
if switches.addChannelLocs

        fprintf('Adding channel locations.. \n');
        AddChannels(params);
        fprintf('Done.\n');

end

%% Extract epochs
if switches.epochData && ~params.isEpoched

        [params] = EpochData(params);

end


%% Baseline correct
if switches.baselineCorrect && strcmp(switchProfile,'stage1')

        fprintf('Baseline correcting... \n');
        BaselineCorrect(params);
        fprintf('Done.\n');

end

%% Create a duplicate of the current file before manual rejections
% This way, if you need to re-do the manual rejections, you can use this
% file.
if switches.firstBackup
    
        fprintf('Backing up file prior to manual rejection... \n');
        BackupFile(params);
        fprintf('Done.\n');
        
end
  
%% Save stage 1 parameters
if strcmp(switchProfile,'stage1')
    parameterFilename = sprintf('%s_preprocessing_params_stage1.mat',params.sbj);
    save([sbjDir parameterFilename],'params');
end

%% Between stages 1 and 2, manually identify and remove bad channels and epochs
% eyeblinks are fine at this stage, but get rid of muscle artefacts and
% skin potentials. proceed with stage 2 when you're done.

%% Check how many epochs have been manually kicked out
if switches.checkFirstManualRemoval
       
        CheckRemoval(params);
           
end

%% Interpolate missing channels - start of stage 2
if switches.interpolateMissingChannels
    
        fprintf('Interpolating missing channels... \n');
        params = InterpolateChannels(params);
        fprintf('Done.\n');
        
end

%% Merge runs
if switches.mergeBeforeICA && ~params.isMerged
    
        fprintf('Merging runs into a single file... \n');
        params = MergeRuns(params);
        fprintf('Done.\n');
        
end

%% Baseline correct
if switches.baselineCorrect && strcmp(switchProfile,'stage2')

        fprintf('Baseline correcting... \n');
        BaselineCorrect(params);
        fprintf('Done.\n');

end

%% Apply ICA 
if switches.firstICA
    
        fprintf('Performing First Independent Components Analysis... \n');
        DoFirstICA(params);
        fprintf('Done.\n');

end

%% Save stage 2 parameters
if strcmp(switchProfile,'stage2')
    parameterFilename = sprintf('%s_preprocessing_params_stage2.mat',params.sbj);
    save([sbjDir parameterFilename],'params');
end
%% Between stages 2 and 3, manually identify eyeblink components 
% then run stage 3, and input the components that you have identified
%% Remove eyeblink components using ICA
if switches.removeBlinks
    
        fprintf('Removing eyeblink components \n');
        params = RemoveBlinks(params);
        fprintf('Done.\n');
    
end

%% Merge runs
if switches.mergeAfterICA && ~params.isMerged
    
        fprintf('Merging runs into a single file... \n');
        params = MergeRuns(params);
        fprintf('Done.\n');
        
end


%% Rereference to average reference
if switches.reref

        fprintf('Rereferencing... \n');
        Rereference(params);
        fprintf('Done.\n');

end

%% Baseline correct
if switches.baselineCorrect && strcmp(switchProfile,'stage3')

        fprintf('Baseline correcting... \n');
        BaselineCorrect(params);
        fprintf('Done.\n');

end
%% Create a duplicate of the current file before manual rejections
% This way, if you need to re-do the manual rejections, you can use this
% file.
if switches.secondBackup
    
        fprintf('Backing up file prior to manual rejection... \n');
        BackupFile(params);
        fprintf('Done.\n');
        
end
  
%% Save stage 3 parameters
if strcmp(switchProfile,'stage3')
    parameterFilename = sprintf('%s_preprocessing_params_stage3.mat',params.sbj);
    save([sbjDir parameterFilename],'params');
end

%% Between stages 3 and 4, manually remove epochs in which eyeblink correction was unsuccessful 
% then run stage 4
%% Check removal
if switches.checkSecondManualRemoval
    
        CheckRemoval(params);
    
end

%% Apply automatic artefact rejection filter
if switches.autoReject
    
        fprintf('Rejecting artefacts automatically with %.0fmV filter...\n', params.autoThreshold);
        AutoReject(params);
        fprintf('Done.\n');
        
end
%% Apply ICA
if switches.finalICA
    
        fprintf('Performing Final Independent Components Analysis... \n');
        params = DoFinalICA(params);
        fprintf('Done.\n');

end
%% Apply CSD 
if switches.CSD
    
        fprintf('Computing CSDs... \n')
        params = RunCSD(params);
        fprintf('Done.\n');

end

%% Baseline correct
if switches.baselineCorrect && strcmp(switchProfile,'stage4')

        fprintf('Baseline correcting... \n');
        BaselineCorrect(params);
        fprintf('Done.\n');

end

%% Convert to ERPLAB-friendly format (for ERP analyses only)
if switches.erplabConvert
    
        fprintf('Making compatible with ERPlab... \n');
        ERPlabConvert(params);
        fprintf('Done.\n');
    
end

%% Clean up output directory
if switches.cleanUpDirectory
    
        fprintf('Cleaning up output directory... \n');
        CleanUpDirectory(params);
        fprintf('Done.\n');
       
end

%% Save stage 4 parameters
if strcmp(switchProfile,'stage4')
    parameterFilename = sprintf('%s_preprocessing_params_stage4.mat',params.sbj);
    save([sbjDir parameterFilename],'params');
end

end
