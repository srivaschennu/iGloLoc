function abort = psychpausefor(pausetime)

global hd

abort = 0;

FlushEvents

s = sprintf('Running %s session',hd.session);
TextBounds = Screen('TextBounds', hd.window, s);
Screen('DrawText',hd.window,s,hd.right/2-TextBounds(3)/2,hd.bottom/2-TextBounds(4)/2,hd.textcolor,hd.bgcolor);
s = sprintf('Press SPACE to wait or Q to quit. Resuming in %02d', 0);
TextBounds = Screen('TextBounds', hd.window, s);
Screen('DrawText',hd.window,s,hd.right/2-TextBounds(3)/2,hd.bottom/2+TextBounds(4),hd.textcolor,hd.bgcolor);
Screen('Flip',hd.window);

for i = pausetime:-1:1
    if CharAvail
        keyPressed = GetChar;
        if str2double(sprintf('%d',keyPressed)) == ' '
            s = sprintf('Running %s session',hd.session);
            TextBounds = Screen('TextBounds', hd.window, s);
            Screen('DrawText',hd.window,s,hd.right/2-TextBounds(3)/2,hd.bottom/2-TextBounds(4)/2,hd.textcolor,hd.bgcolor);
            s = sprintf('Waiting... Press SPACE to continue.');
            TextBounds = Screen('TextBounds', hd.window, s);
            Screen('DrawText',hd.window,s,hd.right/2-TextBounds(3)/2,hd.bottom/2+TextBounds(4),hd.textcolor,hd.bgcolor);
            Screen('Flip',hd.window);
            
            while GetChar ~= ' '
            end
            break
        elseif strcmpi(keyPressed,'q')
            s = sprintf('Aborting...');
            TextBounds = Screen('TextBounds', hd.window, s);
            Screen('DrawText',hd.window,s,hd.right/2-TextBounds(3)/2,hd.bottom/2-TextBounds(4)/2,hd.textcolor,hd.bgcolor);
            Screen('Flip',hd.window);
            
            abort = 1;
            break
        end
    else
        s = sprintf('Running %s session',hd.session);
        TextBounds = Screen('TextBounds', hd.window, s);
        Screen('DrawText',hd.window,s,hd.right/2-TextBounds(3)/2,hd.bottom/2-TextBounds(4)/2,hd.textcolor,hd.bgcolor);
        s = sprintf('Press SPACE to wait or Q to quit. Resuming in %02d', i);
        TextBounds = Screen('TextBounds', hd.window, s);
        Screen('DrawText',hd.window,s,hd.right/2-TextBounds(3)/2,hd.bottom/2+TextBounds(4),hd.textcolor,hd.bgcolor);
        Screen('Flip',hd.window);
        pause(1);
    end
end

fprintf('\n\n');