function igloloc3(session)

if nargin == 0
    session = 'SEQUENCE';
end

%check session type is valid
if ~exist('session','var') || (~strcmp(session,'TONE') && ...
        ~strcmp(session,'SEQUENCE') && ~strcmp(session,'VISUAL'))
    error('Input argument SESSION must be one of ''TONE'' ''SEQUENCE'' or ''VISUAL''.');
end

PsychJavaTrouble

starttime = GetSecs;

global hd

%initialise random number generator
%RandStream.setDefaultStream(RandStream('mt19937ar','seed',sum(100*clock)));
rand('state',sum(100*clock))

%timing parameters
startwaittime = 3; %seconds
srepint1 = 3:4;
srepint2 = 5:6;
isi = 850; %milliseconds
isijitter = 150; %milliseconds

%Sequence frequencies
startcount = 20;
deviantcntbase = [15 15];

if ~isempty(hd) && isstruct(hd)
    fprintf('Found existing run info.\n');
end

% nshost = '10.0.0.42';
% nsport = 55513;

if ~isfield(hd,'nsstatus') && ...
        exist('nshost','var') && ~isempty(nshost) && ...
        exist('nsport','var') && nsport ~= 0
    fprintf('Connecting to Net Station.\n');
    [nsstatus, nserror] = NetStation('Connect',nshost,nsport);
    if nsstatus ~= 0
        error('Could not connect to NetStation host %s:%d.\n%s\n', ...
            nshost, nsport, nserror);
    end
    hd.nsstatus = nsstatus;
end
NetStation('Synchronize');

%init psychtoolbox sound
if ~isfield(hd,'pahandle')
    hd.f_sample = 44100;
    fprintf('Initialising audio.\n');
    
    InitializePsychSound
    
    if PsychPortAudio('GetOpenDeviceCount') == 1
        PsychPortAudio('Close',0);
    end
    
    if isunix
        audiodevices = PsychPortAudio('GetDevices');
        outdevice = strcmp('Built-in Output',{audiodevices.DeviceName});
        hd.outdevice = 1;
    elseif ispc
        audiodevices = PsychPortAudio('GetDevices',2);
        outdevice = strcmp('Microsoft Sound Mapper - Output',{audiodevices.DeviceName});
        hd.outdevice = 3;
    else
        error('Unsupported OS platform!');
    end
    
    hd.pahandle = PsychPortAudio('Open',audiodevices(outdevice).DeviceIndex,[],[],hd.f_sample,2);
end

%create pseudorandom block order
if ~isfield(hd,'blocklist')
    blocklist = [
        'LAX'
        'LAY'
        'LBX'
        'LBY'
        'RAX'
        'RAY'
        'RBX'
        'RBY'
        'XCL'
        'YCL'
        ];
    
    xblocks = find(blocklist(:,3) == 'X');
    blockorder = zeros(length(blocklist),1);
    blockorder(1) = xblocks(ceil(rand*length(xblocks)));
    oblocks = setdiff(1:length(blocklist),blockorder(1));
    
    while true
        oblocks = oblocks(randperm(length(oblocks)));
        blockorder(2:end,1) = oblocks;
        if isempty(strfind(blocklist(blockorder,3)','XXX')) && isempty(strfind(blocklist(blockorder,3)','YYY')) && ...
                isempty(strfind(blocklist(blockorder,2)','AAA')) && isempty(strfind(blocklist(blockorder,2)','BBB'))
            blocklist = blocklist(blockorder,:);
            break;
        end
    end
    
    fprintf('Going to run blocks in this order:\n');
    disp(blocklist);
    hd.blocklist = blocklist;
    clear blocklist
    hd.blocknum = 1;
    
    load('MARKERS.mat');
    hd.MARKERS = MARKERS;
end

% setup psychtoolbox display

hd.bgcolor = [127 127 127];%[255 255 255];
hd.dispscreen = 0;
hd.itemsize = 100;
hd.wsize = (hd.itemsize/2)+30;

hd.textsize = 25;
hd.textfont = 'Helvetica';
hd.textcolor = [255 255 255];%[0 0 0];

hd.session = session;
hd.ontime = 150/1000;
hd.offtime = 850/1000;

hd.colors = [1 0 0; 0 1 0; 0 0 1; 1 1 0; 1 0 1] * 255;
hd.colornames = {'red','green','blue','yellow','magenta'};
hd.letters = {'A' 'E' 'J' 'P' 'T'};

%set Psychtoolbox preferences
Screen('Preference', 'VBLTimestampingMode', 1);
Screen('Preference', 'TextRenderer', 1);
Screen('Preference', 'TextAntiAliasing', 2);
Screen('Preference', 'TextAlphaBlending',1);

%open Psychtoolbox main window
[window,scrnsize] = Screen('OpenWindow', hd.dispscreen, hd.bgcolor);

hd.window = window;
hd.centerx = scrnsize(3)/2;
hd.centery = scrnsize(4)/2;
hd.bottom = scrnsize(4);
hd.right = scrnsize(3);

%disable mouse pointer and matlab keyboard input
HideCursor;
ListenChar(2);

%adjust requested SOA so that it is an exact multiple of the base refresh
%interval of the monitor at the current refresh rate.
refreshInterval = Screen('GetFlipInterval',hd.window);
hd.ontime = ceil(hd.ontime/refreshInterval) * refreshInterval;
hd.offtime = ceil(hd.offtime/refreshInterval) * refreshInterval;
fprintf('\nUsing ON time of %dms with OFF time of %dms.\n', round(hd.ontime*1000), round(hd.offtime*1000));

Screen('TextSize',hd.window,hd.textsize);
Screen('TextFont',hd.window,hd.textfont);

if strcmp(hd.session, 'VISUAL')
    %fixation cross window
    hd.wfix = Screen('OpenOffscreenWindow',hd.window,hd.bgcolor,[1,1,hd.wsize*2,hd.wsize*2]);
    Screen('TextSize',hd.wfix,hd.itemsize);
    Screen('TextFont',hd.wfix,hd.textfont);
    fixc = '+';
    s = sprintf('%c',fixc);
    TextBounds = Screen('TextBounds', hd.wfix, s);
    Screen('DrawText',hd.wfix,s,hd.wsize-TextBounds(3)/2,hd.wsize-TextBounds(4)/2,hd.textcolor,hd.bgcolor);
    
    % create offscreen windows for items to be flashed later
    w = 1;
    for m = 1:length(hd.letters)
        for c = 1:size(hd.colors,1)
            hd.wflash(w) = Screen('OpenOffscreenWindow',hd.window,hd.bgcolor,[1,1,hd.wsize*2,hd.wsize*2]);
            Screen('TextSize',hd.wflash(w),hd.itemsize);
            Screen('TextFont',hd.wflash(w),hd.textfont);
            s = sprintf('%c',hd.letters{m});
            TextBounds = Screen('TextBounds', hd.wflash(w), s);
            Screen('FillRect',hd.wflash(w),hd.bgcolor);
            Screen('DrawText',hd.wflash(w),s,hd.wsize-TextBounds(3)/2,hd.wsize-TextBounds(4)/2,hd.colors(c,:),hd.bgcolor);
            w = w+1;
        end
    end
end

%blank texture
hd.wblank = Screen('OpenOffscreenWindow',hd.window,hd.bgcolor,[1,1,hd.right,hd.bottom]);

if ~isfield(hd,'instraudio')
    %load audio instruction
    hd.instraudio = wavread('Stimuli3/instr.wav')';
end

%loop through block list
while hd.blocknum <= length(hd.blocklist)
    if psychpausefor(20)
        break;
    end
    
    NetStation('Synchronize');
    pause(1);
    NetStation('StartRecording');
    pause(1);
    
    tic;
    
    blockname = hd.blocklist(hd.blocknum,:);
    
    %randomize slightly the sequence counts for each block
    deviantcnt = deviantcntbase + round(rand(size(deviantcntbase))*2)-1;
    
    %setup block stimulus sequence
    
    fprintf('Initialising pseudorandom sequence for  block %d %s.\n', hd.blocknum, blockname);
    if strcmp(blockname,'XCL') || strcmp(blockname,'YCL')
        %prepare control block
        
        if strcmp(blockname,'XCL')
            ctrlaudio = {'LAX2','LAX3','RAX2','RAX3'};
        elseif strcmp(blockname,'YCL')
            ctrlaudio = {'LBY2','LBY3','RBY2','RBY3'};
        end
        
        seqaudio = cell(4,2);
        for s = 1:4
            seqaudio{s,1} = sprintf('%s%d',blockname,s);
            seqaudio{s,2} = wavread(sprintf('Stimuli3/%s.wav',ctrlaudio{s}))';
        end
        
        seqord = zeros(1,120);
        seqord(1:round(length(seqord)/4)) = 1;
        seqord(round(length(seqord)/4)+1:round(length(seqord)/2)) = 2;
        seqord(round(length(seqord)/2)+1:round(length(seqord)*3/4)) = 3;
        seqord(round(length(seqord)*3/4)+1:end) = 4;
        
        while true
            seqord = seqord(randperm(length(seqord)));
            goodrand = true;
            
            for s = 1:length(seqord)-srepint1(1)+1
                if sum(seqord(s:s+srepint1(1)-1) == ones(1,srepint1(1))) == srepint1(1) || ...
                        sum(seqord(s:s+srepint1(1)-1) == ones(1,srepint1(1))*2) == srepint1(1) || ...
                        sum(seqord(s:s+srepint1(1)-1) == ones(1,srepint1(1))*3) == srepint1(1) || ...
                        sum(seqord(s:s+srepint1(1)-1) == ones(1,srepint1(1))*4) == srepint1(1)
                    goodrand = false;
                    break;
                end
            end
            
            if goodrand == true
                break;
            end
        end
        
        fprintf('Running block %d %s with %d sequences.\n', hd.blocknum, blockname, length(seqord));
        
    else
        seqaudio = cell(3,2);
        for s = 1:3
            seqaudio{s,1} = sprintf('%s%d',blockname,s);
            seqaudio{s,2} = wavread(sprintf('Stimuli3/%s%d.wav',blockname,s))';
        end
        
        %setup sequence order and laterality
        
        %randomly select intervals between consecutive deviants
        %     deviantpos = srepint(1)-1+randi(length(srepint),1,seq2count+seq3count);
        deviantpos = zeros(1,sum(deviantcnt));
        deviantpos(1:round(.8*length(deviantpos))) = srepint1(1)-1+Randi(length(srepint1),[1,round(.8*length(deviantpos))]); % 80% of oddball sequences with gap of srepint1
        deviantpos(round(.8*length(deviantpos))+1:end) = srepint2(1)-1+Randi(length(srepint2),[1,length(deviantpos)-round(.8*length(deviantpos))]); % 20% of oddball sequences with gap of srepint2
        
        deviantpos = deviantpos(randperm(length(deviantpos)));
        for p = 2:length(deviantpos)
            deviantpos(p) = deviantpos(p-1) + deviantpos(p);
        end
        deviantpos = deviantpos(randperm(length(deviantpos)));
        
        seqord = zeros(1,max(deviantpos));
        devtype = 0;
        for d = 1:length(deviantcnt)
            seqord(deviantpos(devtype+(1:deviantcnt(d)))) = d; %set positions of deviant type i sequences
            devtype = devtype+deviantcnt(d);
        end
        %standard stimuli are 1, while deviant stimuli are 2 and above
        seqord = seqord + 1;
        
        %prepend habituation sequences prior to actual stimulation sequence
        prefixseq = ones(1,startcount);
        seqord = cat(2,prefixseq,seqord);
        
        fprintf('Running block %d %s with %d sequences: %d (%.1f%%) %d (%.1f%%) %d (%.1f%%).\n', hd.blocknum, blockname, length(seqord(startcount+1:end)), ...
            sum(seqord(startcount+1:end) == 1), mean(seqord(startcount+1:end) == 1)*100,...
            sum(seqord(startcount+1:end) == 2), mean(seqord(startcount+1:end) == 2)*100,...
            sum(seqord(startcount+1:end) == 3), mean(seqord(startcount+1:end) == 3)*100);
    end
    
    %setup auditory stimulus presentation schedule
    nexttime = startwaittime;
    eventlist = zeros(length(seqord),3);
    for e = 1:length(seqord)
        eventlist(e,1) = nexttime;
        eventlist(e,2) = seqord(e);
        nexttime = nexttime + size(seqaudio{eventlist(e,2),2},2)/hd.f_sample + ...
            (isi + round(rand*isijitter*2) - isijitter)/1000;
    end
    
    if strcmp(hd.session, 'VISUAL')
        %setup visual stimulus presentation schedule
        numletters = floor(nexttime / (hd.ontime + hd.offtime));
        letterorder = [];
        for i = 1:ceil(numletters/length(hd.wflash))
            letterorder = [letterorder randperm(length(hd.wflash))];
        end
        
        nexttime = 1;
        for n = 1:numletters
            e = e+1;
            eventlist(e,1) = nexttime;
            eventlist(e,2) = letterorder(n);
            eventlist(e,3) = 1;
            nexttime = nexttime + hd.ontime;
            
            e = e+1;
            eventlist(e,1) = nexttime;
            eventlist(e,3) = -1;
            nexttime = nexttime + hd.offtime;
        end
        
        %sort events by time
        [dummy, evsortidx] = sort(eventlist(:,1));
        eventlist = eventlist(evsortidx,:);
    end
    
    Screen('FillRect',hd.window,hd.bgcolor);
    Screen('Flip',hd.window);
    
    NetStation('Event','BGIN',GetSecs,0.001,'BNUM',hd.blocknum);
    sendmarker_io32(hd.MARKERS.BGIN+hd.blocknum);
    pause(1);
    
    %play audio instruction
    %     PsychPortAudio('FillBuffer',hd.pahandle,hd.instraudio);
    %     PsychPortAudio('Start',hd.pahandle,1,0,1);
    %     NetStation('Event','INST',GetSecs,0.001,'BNUM',hd.blocknum);
    %     PsychPortAudio('Stop',hd.pahandle,1);
    
    if strcmp(hd.session,'TONE')
        s = sprintf('You will hear sequences of 5 sounds');
        TextBounds = Screen('TextBounds', hd.window, s);
        Screen('DrawText',hd.window,s,hd.right/2-TextBounds(3)/2,hd.bottom/2-TextBounds(4)/2,hd.textcolor,hd.bgcolor);
        s = sprintf('Pay attention and count any uncommon sounds');
        TextBounds = Screen('TextBounds', hd.window, s);
        Screen('DrawText',hd.window,s,hd.right/2-TextBounds(3)/2,hd.bottom/2+TextBounds(4),hd.textcolor,hd.bgcolor);
        hd.sesstype = 1;
    
    elseif strcmp(hd.session,'SEQUENCE')
        s = sprintf('You will hear sequences of 5 sounds');
        TextBounds = Screen('TextBounds', hd.window, s);
        Screen('DrawText',hd.window,s,hd.right/2-TextBounds(3)/2,hd.bottom/2-TextBounds(4)/2,hd.textcolor,hd.bgcolor);
        s = sprintf('Pay attention and count any uncommon sequences');
        TextBounds = Screen('TextBounds', hd.window, s);
        Screen('DrawText',hd.window,s,hd.right/2-TextBounds(3)/2,hd.bottom/2+TextBounds(4),hd.textcolor,hd.bgcolor);
        hd.sesstype = 2;
        
    elseif strcmp(hd.session,'VISUAL')
        hd.targletter = ceil(rand*length(hd.letters));
        hd.targcolor = ceil(rand*size(hd.colors,1));
        hd.targitem = ((hd.targletter-1) * length(hd.letters)) + hd.targcolor;
        s = sprintf('Count the number of times you see %s in ',hd.letters{hd.targletter});
        TextBounds = Screen('TextBounds', hd.window, s);
        [newX, newY] = Screen('DrawText',hd.window,s,hd.right/2-TextBounds(3)/2,hd.bottom/2-TextBounds(4)/2,hd.textcolor,hd.bgcolor);
        s = sprintf('%s',hd.colornames{hd.targcolor});
        Screen('DrawText',hd.window,s,newX,newY,hd.colors(hd.targcolor,:),hd.bgcolor);
        hd.sesstype = 3;
    end
    
    NetStation('Event','SESS',GetSecs,0.001,'TYPE',hd.sesstype);
    sendmarker_io32(hd.MARKERS.SESS+hd.sesstype);
    pause(0.5);

    Screen('Flip',hd.window);
    NetStation('Event','VINS',GetSecs,0.001,'BNUM',hd.blocknum);
    sendmarker_io32(hd.MARKERS.VINS);
    pause(8);
    
    Priority(MaxPriority(0));
    curevent = 1;
    eventlist(:,1) = eventlist(:,1) + GetSecs;
    
    tic;
    while true
        curtime = GetSecs;
        
        if curevent <= size(eventlist,1) && eventlist(curevent,1)-curtime <= 0
            if eventlist(curevent,3) == 0
                %fprintf('Delay of %.2f sec\n', eventlist(curevent,1)-curtime);
                PsychPortAudio('FillBuffer',hd.pahandle,seqaudio{eventlist(curevent,2),2});
                PsychPortAudio('Start',hd.pahandle,1,0,1);
                NetStation('Event',seqaudio{eventlist(curevent,2),1},GetSecs,0.001,'BNUM',hd.blocknum);
                sendmarker_io32(hd.MARKERS.(blockname) + eventlist(curevent,2));
                
                %this pause prevents audio distortions on windows
                pause(0.02);
                
            elseif eventlist(curevent,3) == -1
                %blank screen
                Screen('FillRect',hd.window,hd.bgcolor);
                Screen('Flip',hd.window);
                
            elseif eventlist(curevent,3) == 1
                Screen('DrawTexture',hd.window,hd.wflash(eventlist(curevent,2)),...
                    [1,1,hd.wsize*2,hd.wsize*2],...
                    [hd.centerx-hd.wsize,hd.centery-hd.wsize,hd.centerx+hd.wsize,hd.centery+hd.wsize]);
                Screen('Flip',hd.window);
                if eventlist(curevent,2) == hd.targitem
                    NetStation('Event','TARG',GetSecs,0.001,'BNUM',hd.blocknum,'TIDX',eventlist(curevent,2));
                    sendmarker_io32(hd.MARKERS.TARG + eventlist(curevent,2));
                else
                    NetStation('Event','DIST',GetSecs,0.001,'BNUM',hd.blocknum,'DIDX',eventlist(curevent,2));
                    sendmarker_io32(hd.MARKERS.DIST + eventlist(curevent,2));
                end
                
            end
            curevent = curevent + 1;
            
        elseif curevent > size(eventlist,1)
            break;
        end
    end
    tElapsed = toc;
    Priority(0);
    
    pause(1);
    NetStation('Event','BEND',GetSecs,0.001,'BNUM',hd.blocknum);
    sendmarker_io32(hd.MARKERS.BEND+hd.blocknum);
    
    pause(1);
    NetStation('StopRecording');
    
    fprintf('Finished block %d in %.1f min.\n',hd.blocknum,tElapsed/60);
    
    hd.blocknum = hd.blocknum+1;
end

Screen('Close');
clear screen;
ShowCursor;
ListenChar(0);

if hd.blocknum > length(hd.blocklist)
    PsychPortAudio('Close',hd.pahandle);
    
    clear global hd
    fprintf('DONE!\n');
end

stoptime = GetSecs;
fprintf('\nThis run took %.1f min.\n', (stoptime-starttime)/60);