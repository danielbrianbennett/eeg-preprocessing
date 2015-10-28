function compatibilityParams = erplab_compatibility_DARPAK
%%
compatibilityParams.binNumber =         [...
                                        1
                                        ];

compatibilityParams.binDescription =    {...
                                        'feedback'
                                        };
                                    
compatibilityParams.binTest =           {...
                                        'strcmp(EEG.event(eventNumber).type, ''feedback_presentation'')'
                                        };
                                    
%%
compatibilityParams.nBins = numel(compatibilityParams.binNumber);

if ~(compatibilityParams.nBins == numel(compatibilityParams.binDescription)) || ~(compatibilityParams.nBins == numel(compatibilityParams.binTest)) 
    error('Things don''t match up. Check your specifications.');
end
