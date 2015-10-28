function recode_DARPAK(params)
% Use a function like this one to do any of the following:
% 1. Recode triggers
% 2. Delete triggers
% 3. Add new triggers (e.g. a run offset trigger, if you forgot to code one
% initially).
%%%%%%%%%%%%%%%%%%%%%
% Triggers - DARPAK
%%%%%%%%%%%%%%%%%%%%%
% Run Start     -> 90
% Run End       -> 91
% Trial Start   -> 92 (will be preceded by block number (1-15) and then trial number (1-25) triggers)
% Button press  -> 93
% Feedback      -> 94
% Tested with toolbox version 3.0 and eeglab version 12
%% Define trigger codes and what they mean 
%(these should be strings, even if the originals are numbers - see below)
runStart = '90';
runEnd = '91';
trialStart = '92';
buttonPress = '93';
feedbackPresentation = '94';
forDeletion = {'1' '2' '3' '4' '5' '6' '7' '8' '9' '10' '11' '12' '13' '14' '15' '16' '17' '18' '19' '20' '21' '22' '23' '24' '25'};

%% Load in the data using information from the params structure
fprintf('Restarting eeglab... \n');
[ALLEEG EEG CURRENTSET ALLCOM] = eeglab;
fprintf('Done.\n');

filename = [params.sbj params.saveSuffix];

try
    fprintf('Loading run data...\n')
    EEG = pop_loadset('filename', filename, 'filepath', [params.cleandir params.sbj '\'] ); %
    fprintf('Done.\n')
catch
    error('Cannot find data file.')
end

%% If triggers are coded as numbers, recode them as strings (more flexible format for eeglab)
for i = 1:size(EEG.event,2) %loop through triggers
    if isnumeric(EEG.event(i).type)
        EEG.event(i).type = num2str(EEG.event(i).type);
    end    
end

EEG = eeg_checkset( EEG );

%% Get basic information about triggers
allTriggers = {EEG.event(1:end).type};
nTriggers = numel(allTriggers);

%% Add additional event fields to be filled
EEG = pop_editeventfield(EEG,'run','0'); % Create additional event field in all events called 'run', and make its default value the string '0'.
EEG = pop_editeventfield(EEG,'trial','0');
EEG = eeg_checkset(EEG);

%% Recode run start triggers
runStartTriggers = find(strcmp(allTriggers, runStart));

for i = 1:numel(runStartTriggers)
   EEG.event(runStartTriggers(i)).type = 'run_start';
   EEG.event(runStartTriggers(i)).run = num2str(i); 
   EEG.event(runStartTriggers(i)).trial = 'N/A';
end

%% Recode run end triggers
runEndTriggers = find(strcmp(allTriggers,runEnd));

for i = 1:numel(runEndTriggers)
   EEG.event(runEndTriggers(i)).type = 'run_end';
   EEG.event(runEndTriggers(i)).run = num2str(i); 
   EEG.event(runEndTriggers(i)).trial = 'N/A';
end

%% Recode stimulus onset (trial start) triggers
trialStartTriggers = find(strcmp(allTriggers,trialStart));

for i = 1:numel(trialStartTriggers)    
     % get run number and trial number from previous events
    runNumber = EEG.event(trialStartTriggers(i) - 2).type;
    trialNumber = EEG.event(trialStartTriggers(i) - 1).type;
        
    EEG.event(trialStartTriggers(i)).type = 'trial_start';
    EEG.event(trialStartTriggers(i)).run = num2str(runNumber);
    EEG.event(trialStartTriggers(i)).trial = num2str(trialNumber);
end

%% Recode button press triggers
buttonPressTriggers = find(strcmp(allTriggers,buttonPress));

for i = 1:numel(buttonPressTriggers)    
     % get run number and trial number from previous events
    runNumber = EEG.event(buttonPressTriggers(i) - 3).type;
    trialNumber = EEG.event(buttonPressTriggers(i) - 2).type;
        
    EEG.event(buttonPressTriggers(i)).type = 'button_press';
    EEG.event(buttonPressTriggers(i)).run = num2str(runNumber);
    EEG.event(buttonPressTriggers(i)).trial = num2str(trialNumber);
end

%% Recode feedback presentation triggers
feedbackTriggers = find(strcmp(allTriggers,feedbackPresentation));

for i = 1:numel(feedbackTriggers)    
     % get run number and trial number from previous events
    runNumber = EEG.event(feedbackTriggers(i) - 4).type;
    trialNumber = EEG.event(feedbackTriggers(i) - 3).type;
        
    EEG.event(feedbackTriggers(i)).type = 'feedback_presentation';
    EEG.event(feedbackTriggers(i)).run = num2str(runNumber);
    EEG.event(feedbackTriggers(i)).trial = num2str(trialNumber);
end

%% Delete trial number and run number triggers (don't need them any more)
deleteTriggers = find(ismember(allTriggers,forDeletion));
EEG.event( deleteTriggers ) = [];

%% Run EEGLAB routine for checking consistency of events
EEG = eeg_checkset(EEG);

%% Save datafile
savename = [params.sbj params.saveSuffix];
pop_saveset( EEG, 'filename',savename,'filepath',[params.cleandir params.sbj filesep]);

end
