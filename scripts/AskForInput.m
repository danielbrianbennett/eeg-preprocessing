function [params] = AskForInput(params, switches)

if switches.swapChannels %if we are asking for swap channel input
       params.swapChannels = {};

       
       loopSwitch = 1;
       counter = 1;
       while loopSwitch
           
           if isempty(params.swapChannels)
               myText = 'Which channels do you want to swap?\nType the first channel (e.g. CPz) and press enter. Type ''none'' if there are no channels to swap.\n>> ';       
           else
               myText = 'Which channels do you want to swap?\nType the first channel (e.g. CPz) and press enter. Type ''done'' if there are no more channels to swap.\n>> ';       
           end
            reply = input(myText,'s');
            if strcmpi(reply,'done') || strcmpi(reply,'none')
                loopSwitch = 0;
            else
                params.swapChannels{counter,1} = reply;
                myText = 'Now type the channel to swap with.\n>> ';
                reply = input(myText,'s');
                params.swapChannels{counter,2} = reply;
                counter = counter + 1;
            end
       end
       
end



if switches.interpolateMissingChannels %ask for which channels to interpolate
   for r = 1:params.runsToDo
       params.interpolateChannels{r} = {};
       if params.isMerged
           myText = 'Which channels do you want to interpolate?\nType channels (e.g. CPz), pressing enter after each one. Type ''done'' when finished, or ''none'' if there are no bad channels.\n>> ';
       else
           myText = sprintf('Which channels do you want to interpolate for run %.0f?\nType channels (e.g. CPz), pressing enter after each one. Type ''done'' when finished, or ''none'' if there are no bad channels.\n>> ',r);         
       end
       
       loopSwitch = 1;
       while loopSwitch
            reply = input(myText,'s');
            if strcmpi(reply,'done')
                loopSwitch = 0;
            elseif strcmpi(reply,'none')
                params.interpolateChannels{r} = {};
                loopSwitch = 0;
            else
                params.interpolateChannels{r}{end+1} = reply;
            end
       end
       
   end
end

end
