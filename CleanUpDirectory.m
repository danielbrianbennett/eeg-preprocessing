function [params] = CleanUpDirectory(params)
% Tested with toolbox version 3.0 and eeglab version 12

filepath = [params.cleandir params.sbj filesep];

% Leave in files that end in .txt, .mat, _ica2.set, _csd.set,
% _ica2_erp.set, _csd_erp.set.
temp1 = dir([filepath '*_csd*']);
temp2 = dir([filepath '*_ica2*']);
temp3 = dir([filepath '*.txt']);
temp4 = dir([filepath '*.mat']);
files = {temp1.name, temp2.name temp3.name temp4.name};

% create storage folder for intermediate files
intermediateDir = [filepath 'intermediate' filesep];
if ~isdir(intermediateDir);
    mkdir(intermediateDir);
end

% get list of all files in clean folder
y = dir(filepath);

% exclude from this list all that (a) are directories, or (b) are in the
% list we made
index = ~([y.isdir] | ismember({y.name},files));
y = y(index);

for i = 1:numel(y);
    movefile(y(i).name, intermediateDir)
end


end
