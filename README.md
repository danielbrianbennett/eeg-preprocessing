# eeg-preprocessing
EEG Preprocessing Toolbox

Current version is 3.1; created 2013/2014; uploaded to git 2015; written by Daniel Bennett

The toolbox consists of a series of wrapper scripts for EEGLAB (http://sccn.ucsd.edu/eeglab/) allowing (relatively) automated batch processing of EEG datasets. The main script is EEGPreprocessing.m. This runs a series of subscripts in the ../scripts/ directory,  with reference to parameters defined in a config file in the ../config/ directory. Also relies on ERPlab (http://erpinfo.org/erplab) and CSDlab (http://psychophysiology.cpmc.columbia.edu/Software/CSDtoolbox/) in parts.
