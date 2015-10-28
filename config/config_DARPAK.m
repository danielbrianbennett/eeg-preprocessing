function [switches, params] = config_DARPAK(profile)
% Sets up two structures which will determine the course of the
% eeg preprocessing.
%   
%   switches contains a series of binary toggle switches to determine which preprocessing
%       modules will be executed. E.g. setting switches.splitRuns to 1
%       means that the run-splitting module will be executed by
%       eeg_preprocessing.m
%
%   params contains the experiment- and possibly analysis-specific
%       parameters for analysis

%% general settings

% input format parameter
params.askForInput = 1; % Determines whether the script will (=1) or will not (=0) ask the user for input on (a) interpolating channels, and (b) swapping channels, or whether it will simply use values defined in the config file. see participant-specific parameter section below.

% general analysis parameters
params.inRef = 69; %Electrode to reference to on import; 32=Cpz, 48=Cz. Only relevant for .edf files
params.mastoids = [65 66]; %channel numbers of mastoid electrodes
params.reference = params.mastoids; %Electrode indices of reference electrodes. Use params.mastoids for mastoid reference, or leave as [] for average reference
params.nChannels = 68; %number of channels to work with after all useless channels are deleted
params.dataChannels = 1:64; %number of data-only channels (ie no EKG, EOG, or mastoids)
params.deleteChannels = {'EXG5' 'EXG6' 'EXG7' 'EXG8'}; %channels to be deleted on import
params.electrodeLabelFile = 'standard-10-5-cap385.elp'; %name of file containing electrode locations
params.runOnsetTrigger = 'run_start'; %trigger indicating run onset; must be a string!
params.runEndTrigger = []; %trigger indicating end of experiment (or end of trial, it doesn't matter too much)
params.nRuns = 14; %number of runs to be processed
params.whichRuns = []; %optional; if number of runs found exceeds the number of runs we want, we will process this subset of runs
params.highpassCutoff = 0.1; %lowest frequency (in Hz) which will survive highpass filter
params.lowpassCutoff = 70; %highest frequency (in Hz) which will survive lowpass filter
params.notchCutoff = [45 55]; % [lower, upper] bounds on notch filter
params.eventRecodingScript = @recode_DARPAK; %script which recodes events. must take a certain form; for details, look at example scripts like for 'recode_DARPAK.m'
params.csdLabelsFile = 'labels.txt';
params.csdMontage = '10-5-System_Mastoids_EGI129.csd';
params.nComponentsPlotted = 20; %number of components displayed when selecting which to remove for eyeblink correction
params.autoThreshold = 200; %Threshold for automatic rejection of artefacts at the end of preprocessing (500 mv)

% epoching-related parameters
params.nEpochDivisions = 1; %number of different ways to slice the continuous data into epochs; specify time-locking events and timepoints below
params.epochNames = {'feedback_locked'}; %names for the epoch profile(s); each of these must be accompanied by a separate entry for the three fields below. if more than 1 profile, concatenate them in a cell: e.g. params.epochNames = {'response_locked','feedback_locked'};
params.epochTimeLockEvents = {'feedback_presentation'}; %event to which epochs are time-locked. if more than 1 profile, concatenate them in a cell: e.g. params.epochNames = {'response_locked','feedback_locked'};
params.epochTimes = {[-1.5 1.5]}; %times (in seconds) relative to time locking event to extract as epoch.  if more than 1 profile, concatenate them in a cell: e.g. params.epochTimes = {[-1.5 1.5], [-1.5 1.5]};
params.epochBaselines = {[-200 0]}; %times (in milliseconds) relative to time locking event to use as baseline. if more than 1 profile, concatenate them in a cell: e.g. params.epochBaselines = {[-1500 -1300], [-200 0]};
params.erplabCompatibilityScripts = {@erplab_compatibility_DARPAK}; % script which assigns events to ERPLAB bins. must take a certain form; for details, look at example scripts like for 'erplab_compatibility_DARPAK.m'. if you have a different binning format for different epoch types, include the different functions here in a cell: e.g. {@erplab_compatibility__responselocked_DARPAK, @erplab_compatibility__stimuluslocked_DARPAK}.

% Set some directories
if ismac
    params.rawdir = '/Volumes/333-fbe/DATA/DANDEC/data/EEG/participant_data/'; %location of raw files
    params.cleandir = '/Volumes/333-fbe/DATA/DANDEC/data/EEG/participant_data/'; %location to write cleaned files to
    params.electrodelabels_path = '/usr/eeglab11_0_3_1b/plugins/dipfit2.2/standard_BESA/'; %directory containing electrode labels file
    params.csdLabelsPath = ''; %directory containing current source density labels
elseif isunix
    params.rawdir = '/gpfs/M2Home/projects/pMelb0107/DATA/DANDEC/data/EEG/participant_data/';
    params.cleandir = '/gpfs/M2Home/projects/pMelb0107/DATA/DANDEC/data/EEG/participant_data/';
    params.electrodelabels_path = '/gpfs/M2Home/projects/pMelb0107/CODE/toolboxes/eeglab/eeglab11_0_4_3b/plugins/dipfit2.2/standard_BESA/';
    params.csdLabelsPath = ''; %directory containing current source density labels
else
    params.rawdir = 'Q:\DATA\DARPAK\raw\eeg\';
    params.cleandir = 'Q:\DATA\DARPAK\data\eeg\';
    params.electrodelabels_path = 'Q:\CODE\TOOLBOXES\eeglab11_0_4_3b\plugins\dipfit2.2\standard_BESA\';  
    params.csdLabelsPath = 'Q:\CODE\TOOLBOXES\CSDtoolbox\'; %directory containing current source density labels
end

%% participant-specific settings (will only be used if params.askForInput is set to 0!)
params.swapChannels = {... %This one should contain a series of cells, each with two channel names,for where we have used one channel to replace another. Example: to swap Cz and T8 as well as Fz and T7, you would enter the follwing: { {'Cz','T8'}, {'Fz', "T7'} }
%                         {'', ''}
%                         {'', ''}
                        };

params.interpolateChannels = {... % this one should be filled in with bad channels to be interpolated on a participant-by-participany and run-by-run basis, with a cell for each run (even if no channels are to be removed in that run: e.g. { {'FPz'}, {'FPz','Cz'} {} }       
                                {}
                                {}
                                {}
                                {}
                                {}
                                {}
                                {}
                                {}
                                {}
                                {}
                                {}
                                {}
                                {}
                                {}
                                    }; 
          
                                
%% set all processing pipeline switches to zero (we will change the relevant ones in the next section)
%STAGE 1
switches.loadDataset = 0; % load in master dataset
switches.recodeEvents = 0; % recode events using user-created script
switches.swapChannels = 0; % swap data channels
switches.splitRuns = 0; %split runs and process separately (saves time; good for large files)
switches.deleteChannels = 0; %delete unused channels (which channels to delete defined above)
switches.highpassFilter = 0; % cutoff defined above
switches.lowpassFilter = 0; % cutoff defined above
switches.notchFilter = 0; %notch filter data
switches.reref = 0; %rereference to electrodes defined above
switches.addChannelLocs = 0; %add channel locations from a separate config file (location and name defined above)
switches.epochData = 0; %divide continuous file into epochs according to settings specified above
switches.baselineCorrect = 0; % baseline correct epochs
switches.firstBackup = 0; % create a backup of the stage 1 file prior to manual rejections
%STAGE 2
switches.checkFirstManualRemoval = 0; 
switches.interpolateMissingChannels = 0; %use EEGLAB's spline interpolation of missing electrodes
switches.mergeBeforeICA = 0;
switches.firstICA = 0; %use ICA to identify an eyeblink component; requires manual removal  
%STAGE 3
switches.removeBlinks = 0; %Manual interface to remove eyeblink components
switches.mergeAfterICA = 0;
switches.rereference = 0;
switches.baselineCorrect = 0;
switches.secondBackup = 0; % create a backup of the stage 3 file prior to manual rejections
%STAGE 4
switches.checkSecondManualRemoval = 0;
switches.autoReject = 0;
switches.finalICA = 0; %perform a final Independent Components Analysis on the merged data
switches.CSD = 0; %apply current source density analysis to dataend
switches.erplabConvert = 0; % convert to erplab-friendly format
switches.cleanUpDirectory = 0; % tidy up the output file directory

%% Activate the relevant switches for the chosen profile, and set a few specific parameters
switch profile
    case 'stage1'
        switches.loadDataset = 1; % load in master dataset
        switches.recodeEvents = 1; % recode events using user-created script
        switches.swapChannels = 1; % swap data channels
        switches.splitRuns = 1; %split runs and process separately (saves time; good for large files)
        switches.deleteChannels = 1; %delete unused channels (which channels to delete defined above)
        switches.highpassFilter = 1; % cutoff defined above
        switches.lowpassFilter = 1; % cutoff defined above
        switches.notchFilter = 1; %notch filter data
        switches.reref = 1; %rereference to electrodes defined above
        switches.addChannelLocs = 1; %add channel locations from a separate config file (location and name defined above)
        switches.epochData = 1; %divide continuous file into epochs according to settings specified above
        switches.baselineCorrect = 1; % baseline correct epochs
        switches.firstBackup = 1; % create a backup of the stage 1 file prior to manual rejections
        
        params.saveSuffix = '_stage1.set'; %suffix upon first load of a saved file; will be updated throughout processing as filename changes
        params.isEpoched = 0;
        params.isMerged = 1;
        
    case 'stage2'
        switches.checkFirstManualRemoval = 1; 
        switches.interpolateMissingChannels = 1; %use EEGLAB's spline interpolation of missing electrodes
        switches.mergeBeforeICA = 1;
        switches.baselineCorrect = 1; % baseline correct epochs
        switches.firstICA = 1; %use ICA to identify an eyeblink component; requires manual removal  
        
        params.saveSuffix = '_epochs.set'; %suffix upon first load of a saved file; will be updated throughout processing as filename changes
        params.isEpoched = 1;
        params.isMerged = 0;
        
    case 'stage3'
        switches.removeBlinks = 1; %Manual interface to remove eyeblink components
        switches.baselineCorrect = 1; % baseline correct epochs
        switches.rereference = 1;
        switches.secondBackup = 1; % create a backup of the stage 3 file prior to manual rejections
        
        params.saveSuffix = '_ica1.set'; %suffix upon first load of a saved file; will be updated throughout processing as filename changes
        params.isEpoched = 1;
        params.isMerged = 1;
        
    case 'stage4'
        switches.checkSecondManualRemoval = 1;
        switches.autoReject = 1;
        switches.finalICA = 1; %perform a final Independent Components Analysis on the merged data
        switches.CSD = 1; %apply current source density analysis to dataend
        switches.baselineCorrect = 1;
        switches.erplabConvert = 1; % convert to erplab-friendly format
        switches.cleanUpDirectory = 1; % tidy up the output file directory

        params.saveSuffix = '_stage3.set'; %suffix upon first load of a saved file; will be updated throughout processing as filename changes
        params.isEpoched = 1;
        params.isMerged = 1;
        
    case 'custom'
%         % set custom switches and params here if desired.
%         
%         params.saveSuffix = '_epochs.set'; %fill in depending on which point of the experiment you're at
%         params.isEpoched = 0;
%         params.isMerged = 0;
    otherwise error('Invalid processing pipeline selected!');
end
