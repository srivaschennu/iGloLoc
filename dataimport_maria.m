function dataimport_maria(basename)

loadpaths

load paradigm/MARKERS_short.mat
[~,~,markers] = xlsread('MARKERS_short.xls');
markers = markers(2:end,[1 2 3]);

EEG = pop_loadset('filepath',filepath,'filename',[basename '.set']);

%% Downsample data
if EEG.srate == 512
    fprintf('Downsampling data.\n');
    EEG = pop_resample(EEG,EEG.srate/2);
end

%% Filter the data
lpfreq = 20;
fprintf('Low-pass filtering below %dHz...\n',lpfreq);
EEG = pop_eegfiltnew(EEG, 0, lpfreq);
hpfreq = 0.5;
fprintf('High-pass filtering above %dHz...\n',hpfreq);
EEG = pop_eegfiltnew(EEG, hpfreq, 0);

%% Rename markers
fprintf('Renaming markers.\n');
for e = 1:length(EEG.event)
    midx = str2double(EEG.event(e).type);
    if midx > size(markers,1)
        fprintf('Skipping unrecognised marker %d@%d...\n',midx,e);
        continue;
    end
    
    if strcmp(markers{midx,2},'EMPTY')
        error('Unrecognised event %d at position %d.',midx,e);
    end
    
    if isnan(markers{midx,3})
        EEG.event(e).type = markers{midx,2};
    else
        EEG.event(e).type = sprintf('%s%d',markers{midx,2},markers{midx,3});
    end
    
    EEG.event(e).codes = {'MIDX' midx-find(strcmp(markers{midx,2},markers(:,2)),1)+1};
    evtype = EEG.event(e).type;
    
    switch evtype
        case 'BGIN'
            stdcount = 0;
            prevdev = 0;
            firstdev = false;
            
        otherwise
            switch evtype(1:3)
                case {'CTL'}
                    %do not change any markers in control blocks
                    
                case {'LAX','LAY','RBX','RBY'}
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

