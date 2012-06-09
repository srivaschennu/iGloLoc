function sendmarker(value)

% set EEGMODE to 'true', to enable sending of triggers to EEG amplifier
EEGMODE = true;

% amount of time to pause after sending a marker. This is necessary for the
% parallel port to work correctly
MARKERPAUSE = 0.05;

%fprintf('sendmarker %03d\n',value);

if EEGMODE && IsWin
    PortIO(2,888,value);
    pause(MARKERPAUSE);
    PortIO(2,888,0);
end

end