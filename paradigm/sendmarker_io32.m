function sendmarker_io32(value)

global pportobj pportaddr

% amount of time to pause after sending a marker. This is necessary for the
% parallel port to work correctly
MARKERPAUSE = 0.05;

% fprintf('sendmarker %03d\n',value);

if IsWin && ~isempty(pportobj)
    io32(pportobj,pportaddr,value);
    pause(MARKERPAUSE);
%     io32(pportobj,pportaddr,0);
%     pause(0.02);
end

end