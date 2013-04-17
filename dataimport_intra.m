function dataimport_intra(basename)

loadpaths

load chanlist_intra.mat

[~,~,markers] = xlsread('MARKERS.xls');
markers = markers(2:end,[1 2 3]);

%% import data into EEGLAB
fprintf('Loading data from %s...\n',[filepath basename '.mat']);
load([filepath basename '.mat']);
assignin('base','data',data);
EEG = pop_importdata('dataformat','array','nbchan',0,'data','data','setname','mechulan_sequences',...
    'srate',2000,'pnts',0,'xmin',0);
evalin('base','clear data');

for chan = 1:EEG.nbchan
    EEG.chanlocs(chan).labels = deblank(labels{chan});
end

%% import events into EEGLAB
EEG = pop_chanevent(EEG, EEG.nbchan,'edge','leading','edgelen',0);

%% keep only selected channels
fprintf('Removing excluded channels.\n');
for chan = 1:length(chanlist)
    chanidx(chan) = find(strcmp(chanlist{chan},labels));
end
EEG = pop_select(EEG,'channel',chanidx);

%% Downsample data
samprate = 250;
EEG = pop_resample(EEG,samprate);

%% Filter the data
lpfreq = 40;
fprintf('Low-pass filtering below %dHz...\n',lpfreq);
EEG = pop_eegfilt(EEG, 0, lpfreq, [], [0], 0, 0, 'fir1', 0);
% hpfreq = 0.5;
% fprintf('High-pass filtering above %dHz...\n',hpfreq);
% EEG = pop_eegfilt(EEG, hpfreq, 0, [], [0], 0, 0, 'fir1', 0);

%%Remove line noise
fprintf('Removing line noise at 50Hz.\n');
EEG = rmlinenoisemt(EEG);

%% Rename markers
fprintf('Renaming markers.\n');
for e = 1:length(EEG.event)
    midx = str2double(EEG.event(e).type);
    if midx > size(markers,1)
        fprintf('Skipping unrecognised marker %d@%d...\n',midx,e);
        continue;
    end
    
    if isnan(markers{midx,3})
        EEG.event(e).type = markers{midx,2};
    else
        EEG.event(e).type = sprintf('%s%d',markers{midx,2},markers{midx,3});
    end
    
    EEG.event(e).codes = {};
    evtype = EEG.event(e).type;
    
    switch evtype
        case 'BGIN'
            stdcount = 0;
            prevdev = 0;
            firstdev = false;
            
        otherwise
            switch evtype(1:3)
                case {'XCL','YCL'}
                    %do not change any markers in control blocks
                    
                case {'LAX','LAY','LBX','LBY','RAX','RAY','RBX','RBY'}
                    if ~exist('stdcount','var')
                        stdcount = 0;
                        prevdev = 0;
                        firstdev = false;
                    end
            
                    stimtype = str2double(evtype(4));
                    switch stimtype
                        case 1
                            EEG.event(e).codes = cat(1,EEG.event(e).codes,{'SNUM',stdcount});
                            EEG.event(e).codes = cat(1,EEG.event(e).codes,{'PRED',prevdev});
                            if firstdev
                                stdcount = stdcount + 1;
                            end
                            
                        case {2,3}
                            if firstdev == false
                                firstdev = true;
                            end
                            prevdev = stimtype;
                            stdcount = 1;
                        otherwise
                            error('Unrecognised stimulus type for event %s.',evtype);
                    end
            end
    end
end

%% Save the data
EEG.setname = sprintf('%s_orig',basename);
EEG.filename = sprintf('%s_orig.set',basename);
EEG.filepath = filepath;

fprintf('Saving %s%s.\n', EEG.filepath, EEG.filename);
pop_saveset(EEG,'filename', EEG.filename, 'filepath', EEG.filepath);

