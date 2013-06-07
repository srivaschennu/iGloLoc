function igloloc

starttime = GetSecs;

global hd nsstatus

%initialise random number generator
RandStream.setDefaultStream(RandStream('mt19937ar','seed',sum(100*clock)));

%timing parameters
startwaittime = 3; %seconds
srepint1 = 3:4;
srepint2 = 5:6;
isi = 850; %milliseconds
isijitter = 150; %milliseconds

%Sequence frequencies
startcount = 20;
seq1count = 100;
seq2countbase = 20;
seq3countbase = 20;

if ~isempty(hd) && isstruct(hd)
    fprintf('Found existing run info.\n');
end

nshost = '10.0.0.42';
nsport = 55513;

if isempty(nsstatus) && ...
        exist('nshost','var') && ~isempty(nshost) && ...
        exist('nsport','var') && nsport ~= 0
    fprintf('Connecting to Net Station.\n');
    [nsstatus, nserror] = NetStation('Connect',nshost,nsport);
    if nsstatus ~= 0
        error('Could not connect to NetStation host %s:%d.\n%s\n', ...
            nshost, nsport, nserror);
    end
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
    
    %Try Terratec DMX ASIO driver first. If not found, revert to
    %native sound device
    if ispc
        audiodevices = PsychPortAudio('GetDevices',3);
        if ~isempty(audiodevices)
            %DMX audio
            outdevice = strcmp('DMX 6Fire USB ASIO Driver',{audiodevices.DeviceName});
            hd.outdevice = 'dmx';
        else
            %Windows default audio
            audiodevices = PsychPortAudio('GetDevices',2);
            outdevice = strcmp('Microsoft Sound Mapper - Output',{audiodevices.DeviceName});
            hd.outdevice = 'base';
        end
    elseif ismac
        audiodevices = PsychPortAudio('GetDevices');
        %DMX audio
        outdevice = strcmp('TerraTec DMX 6Fire USB',{audiodevices.DeviceName});
        hd.outdevice = 'dmx';
        if sum(outdevice) ~= 1
            %Mac default audio
            audiodevices = PsychPortAudio('GetDevices');
            outdevice = strcmp('Built-in Output',{audiodevices.DeviceName});
            hd.outdevice = 'base';
        end
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
    
%     load('MARKERS.mat');
%     hd.MARKERS = MARKERS;    
end

if ~isfield(hd,'instraudio')
    %load audio instruction
    hd.instraudio = wavread('Stimuli/instr.wav')';
end

%loop through block list
while hd.blocknum <= length(hd.blocklist)
    if pausefor(15)
        break;
    end
    
    NetStation('Synchronize');
    pause(1);
    NetStation('StartRecording');
    pause(1);
    
    tic;
    
    blockname = hd.blocklist(hd.blocknum,:);
    
    %randomize slightly the sequence counts for each block
    seq2count = seq2countbase + round(rand*2)-1;
    seq3count = seq3countbase + round(rand*2)-1;
    
    %load audio files for this block
    
    if strcmp(blockname,'XCL') || strcmp(blockname,'YCL')
        
        if strcmp(blockname,'XCL')
            ctrlaudio = {'LAX2','LBX2','RAX2','RBX2'};
        elseif strcmp(blockname,'YCL')
            ctrlaudio = {'LAY2','LBY2','RAY2','RBY2'};
        end
        
        seqaudio = cell(4,2);
        for s = 1:4
            seqaudio{s,1} = sprintf('%s%d',blockname,s);
            seqaudio{s,2} = wavread(sprintf('Stimuli/%s.wav',ctrlaudio{s}))';
        end
        
        seqlist = zeros(1,startcount+seq1count+seq2count+seq3count);
        seqlist(1:round(length(seqlist)/4)) = 1;
        seqlist(round(length(seqlist)/4)+1:round(length(seqlist)/2)) = 2;
        seqlist(round(length(seqlist)/2)+1:round(length(seqlist)*3/4)) = 3;
        seqlist(round(length(seqlist)*3/4)+1:end) = 4;
        
        fprintf('Running block %d %s with %d sequences.\n', hd.blocknum, blockname, length(seqlist));
        
    else
        seqaudio = cell(3,2);
        for s = 1:3
            seqaudio{s,1} = sprintf('%s%d',blockname,s);
            seqaudio{s,2} = wavread(sprintf('Stimuli/%s%d.wav',blockname,s))';
        end
        
        %setup sequence order
        seqlist = zeros(1,seq1count+seq2count+seq3count);
        
        %     seq23pos = srepint(1)-1+randi(length(srepint),1,seq2count+seq3count);
        
        seq23pos = cat(2, srepint1(1)-1+randi(length(srepint1),1,round((seq2count+seq3count)*.8)),... % 80% of oddball sequences with gap of srepint1
            srepint2(1)-1+randi(length(srepint2),1,round((seq2count+seq3count)*.2))); % 20% of oddball sequences with gap of srepint2
        
        seq23pos = seq23pos(randperm(length(seq23pos)));
        
        prevpos = 0;
        for p = 1:length(seq23pos)
            seq23pos(p) = prevpos + seq23pos(p);
            prevpos = seq23pos(p);
        end
        seq23pos = seq23pos(randperm(length(seq23pos)));
        seqlist(seq23pos(1:seq2count)) = 2;
        seqlist(seq23pos(seq2count+1:end)) = 3;
        seqlist(seqlist == 0) = 1;
        seqlist = cat(2,ones(1,startcount),seqlist);
        
        fprintf('Running block %d %s with %d sequences: %d (%.1f%%) %d (%.1f%%) %d (%.1f%%).\n', hd.blocknum, blockname, length(seqlist(startcount+1:end)), ...
            sum(seqlist(startcount+1:end) == 1), mean(seqlist(startcount+1:end) == 1)*100,...
            sum(seqlist(startcount+1:end) == 2), mean(seqlist(startcount+1:end) == 2)*100,...
            sum(seqlist(startcount+1:end) == 3), mean(seqlist(startcount+1:end) == 3)*100);
    end
    
    %setup execution plan
    nexttime = startwaittime;
    eventlist = zeros(length(seqlist),2);
    for e = 1:length(seqlist)
        eventlist(e,1) = nexttime;
        eventlist(e,2) = seqlist(e);
        nexttime = nexttime + size(seqaudio{eventlist(e,2),2},2)/hd.f_sample + ...
            (isi + round(rand*isijitter*2) - isijitter)/1000;
    end
    
    NetStation('Event','BGIN',GetSecs,0.001,'BNUM',hd.blocknum);
    %sendmarker(hd.MARKERS.BGIN+hd.blocknum);
    pause(1);
    
    %play instruction
    PsychPortAudio('FillBuffer',hd.pahandle,hd.instraudio);
    PsychPortAudio('Start',hd.pahandle,1,0,1);
    NetStation('Event','INST',GetSecs,0.001,'BNUM',hd.blocknum);
    %sendmarker(hd.MARKERS.VINS);
    PsychPortAudio('Stop',hd.pahandle,1);
    
    Priority(MaxPriority(0));
    curevent = 1;
    eventlist(:,1) = eventlist(:,1) + GetSecs;
    
    tic;
    while true
        curtime = GetSecs;
        
        if curevent <= size(eventlist,1) && eventlist(curevent,1)-curtime <= 0
            %fprintf('Delay of %.2f sec\n', eventlist(curevent,1)-curtime);
            PsychPortAudio('FillBuffer',hd.pahandle,seqaudio{eventlist(curevent,2),2});
            PsychPortAudio('Start',hd.pahandle,1,0,1);
            NetStation('Event',seqaudio{eventlist(curevent,2),1},GetSecs,0.001,'BNUM',hd.blocknum);
            %sendmarker(hd.MARKERS.(blockname) + eventlist(curevent,2));
            curevent = curevent + 1;
            
            %Wait till sound stops playing... ensures better playback on
            %Windows
            PsychPortAudio('Stop',hd.pahandle,1);
            
        elseif curevent > size(eventlist,1)
            break;
        end
    end
    tElapsed = toc;
    Priority(0);
    
    pause(1);
    NetStation('Event','BEND',GetSecs,0.001,'BNUM',hd.blocknum);
    %sendmarker(hd.MARKERS.BEND+hd.blocknum);
    
    pause(1);
    NetStation('StopRecording');
    
    fprintf('Finished block %d in %.1f min.\n',hd.blocknum,tElapsed/60);
    
    hd.blocknum = hd.blocknum+1;
end

if hd.blocknum > length(hd.blocklist)
    PsychPortAudio('Close',hd.pahandle);
    clear global hd
    fprintf('DONE!\n');
end

stoptime = GetSecs;
fprintf('\nThis run took %.1f min.\n', (stoptime-starttime)/60);