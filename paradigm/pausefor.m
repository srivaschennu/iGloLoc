function abort = pausefor(pausetime)

abort = 0;

FlushEvents

fprintf('\nPress SPACE to wait or Q to quit. Continuing in %02d', 0);
for i = pausetime:-1:1
    if CharAvail
        keyPressed = GetChar;
        if str2double(sprintf('%d',keyPressed)) == ' '
            fprintf('\nWaiting... Press SPACE to continue.');
            while GetChar ~= ' '
            end
            break
        elseif strcmpi(keyPressed,'q')
            fprintf('\nAborting...');
            abort = 1;
            break
        end
    else
        fprintf('\b\b%02d',i);
        pause(1);
    end
end

fprintf('\n\n');