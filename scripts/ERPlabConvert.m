function [params] = ERPlabConvert(params)
% Tested with toolbox version 3.0 and eeglab version 12

for i = 1:params.nEpochDivisions

    fprintf('Restarting eeglab... \n');
    close all
    [ALLEEG EEG CURRENTSET ALLCOM] = eeglab;
    fprintf('Done.\n');

    % Work out a list of files to work on - this will be those ending in either
    % _ica2.set or _csd.set
    filepath = [params.cleandir params.sbj filesep];
    temp1 = dir([filepath '*' params.epochNames{i} '_stage3.set']);
temp2.name = [];
%     temp1 = dir([filepath '*' params.epochNames{i} '_csd.set']);
%     temp2 = dir([filepath '*' params.epochNames{i} '_ica2.set']);
    if isempty({temp2.name})
        temp2 = dir([filepath '*' params.epochNames{i} '_stage3.set']);
    end
%     files = {temp1.name, temp2.name};
files = {temp1.name};

    % Load in all the files
    for ii = 1:numel(files)

        filename = files{ii};

        try
            fprintf('Loading run data...\n')
            EEG = pop_loadset('filename', filename, 'filepath', [params.cleandir params.sbj filesep] );
            [ALLEEG, EEG, CURRENTSET] = eeg_store( ALLEEG, EEG, 0 );
            fprintf('Done.\n')
        catch
            error('Cannot find data file.')
        end


    end

    % Work through the files
    for ii = 1:numel(ALLEEG)

        [ALLEEG EEG CURRENTSET] = pop_newset(ALLEEG, EEG, CURRENTSET,'retrieve',ii,'study',0);
        
        savename_regexp = '^[a-zA-Z_0-9]+';
        savename = regexp(files{ii},savename_regexp,'match'); 
        savename = [cell2mat(savename) '_erp.set'];
        
        compatibilityParams = params.erplabCompatibilityScripts{i}();
        EEG = makeERPLABcompatible(EEG, compatibilityParams);
        EEG = eeg_checkset( EEG );
        
        % save run data to disk
        EEG = pop_saveset( EEG, 'filename',savename,'filepath',[params.cleandir params.sbj filesep]);

    end


    fid = fopen(sprintf('%spreprocessing_summary_%s.txt', [params.cleandir params.sbj filesep], params.sbj), 'a+');      
    fprintf(fid, '\t Files made ERPLAB-friendly using the file %s.\n',func2str(params.erplabCompatibilityScripts{i}));
    fclose(fid);

end


    function OUTEEG = makeERPLABcompatible(EEG, compatibilityParams)
    % compatibility params should have fields:
    %   nBins
    %   binDescription (cell with nBins number of fields)
    %   binNumber
    %   binTest


    EVENTLIST = [];

    EVENTLIST.setname = EEG.setname;
    EVENTLIST.report = '';
    EVENTLIST.bdfname = '';
    EVENTLIST.version = geterplabversion;
    EVENTLIST.account = '';
    EVENTLIST.username = '';
    EVENTLIST.elname = fullfile(EEG.filepath,[EVENTLIST.setname '_erplab_events.txt']);
    EVENTLIST.eldate = datestr(now);

    EVENTLIST.nbin = compatibilityParams.nBins;

    for bin = 1:EVENTLIST.nbin
        EVENTLIST.bdf(1,bin).description = compatibilityParams.binDescription{bin};
        EVENTLIST.bdf(1,bin).namebin = ['BIN' num2str(bin)];
    end


    for eventNumber = 1:numel(EEG.event)

        % Calculate some simple information about this event
        EVENTLIST.eventinfo(1,eventNumber).item = eventNumber; % item number = EEG event number
        EVENTLIST.eventinfo(1,eventNumber).spoint = EEG.event(eventNumber).latency; % sample point = EEG latency (which is calculated in samples)
        EVENTLIST.eventinfo(1,eventNumber).time = EEG.event(eventNumber).latency / EEG.srate; % divide this by the sampling rate to get the time in seconds
        EVENTLIST.eventinfo(1,eventNumber).dura = 0; % duration of event = 0 (other values technically possible but we won't use them.)
        EVENTLIST.eventinfo(1,eventNumber).flag = 0; % erplab includes the option of flagging bad events using this field. We won't use it.
        EVENTLIST.eventinfo(1,eventNumber).enable = 1; % individual events can be turned off by setting this to zero.

        % Work out what bin this event belongs in (if any)
        binTest = nan(1,EVENTLIST.nbin); % initialise each as nan

        for bin = 1:EVENTLIST.nbin          
           binTest(bin) = eval(compatibilityParams.binTest{bin});
        end

        if ~any(binTest) % if the event isn't included in any bin
            EVENTLIST.eventinfo(1,eventNumber).code = EEG.event(eventNumber).type; % if not in a bin, its code is just its original event label
            EVENTLIST.eventinfo(1,eventNumber).binlabel = '""'; % and its binlabel is a string like this
            EVENTLIST.eventinfo(1,eventNumber).codelabel = '""'; % and so is its codelabel
            EVENTLIST.eventinfo(1,eventNumber).bini = -1; % if not in a bin, set bini to -1
            EVENTLIST.eventinfo(1,eventNumber).bepoch = 0; % if not in a bin, set bepoch to 0
        elseif sum(binTest) > 1 % the event is included in more than one bin
            error('Error: more than one bin type detected for event %.0f.', eventNumber)
        elseif sum(binTest) == 1 % if the event is in one and only one bin
            EVENTLIST.eventinfo(1,eventNumber).code = compatibilityParams.binNumber(find(binTest)); % numeric bin number
            EVENTLIST.eventinfo(1,eventNumber).binlabel = compatibilityParams.binDescription{find(binTest)}; % and its binlabel is a string like this
            EVENTLIST.eventinfo(1,eventNumber).codelabel = compatibilityParams.binDescription{find(binTest)}; % and so is its codelabel
            EVENTLIST.eventinfo(1,eventNumber).bini = compatibilityParams.binNumber(find(binTest)); % numeric bin number
            EVENTLIST.eventinfo(1,eventNumber).bepoch = EEG.event(eventNumber).epoch; % if not in a bin, set bepoch to 0       
        end

    end


    OUTEEG = EEG;
    OUTEEG.EVENTLIST = EVENTLIST;

    % Update the EEG.epoch structure with values calculated in the previous
    % steps
    for iii = 1:size(EEG.epoch,2)

        try
            epochEventNumbers = EEG.epoch(iii).event;
        catch
            epochEventNumbers = iii;
        end


        OUTEEG.epoch(iii).eventflag = {EVENTLIST.eventinfo(epochEventNumbers).flag};
        OUTEEG.epoch(iii).eventitem = {EVENTLIST.eventinfo(epochEventNumbers).item};    
        OUTEEG.epoch(iii).eventbepoch = {EVENTLIST.eventinfo(epochEventNumbers).bepoch};
        OUTEEG.epoch(iii).eventbini = {EVENTLIST.eventinfo(epochEventNumbers).bini};
        OUTEEG.epoch(iii).eventbinlabel = {EVENTLIST.eventinfo(epochEventNumbers).binlabel};
        OUTEEG.epoch(iii).eventcodelabel = {EVENTLIST.eventinfo(epochEventNumbers).codelabel};
        OUTEEG.epoch(iii).eventenable = {EVENTLIST.eventinfo(epochEventNumbers).enable};

    end


    end

end
