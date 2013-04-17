function dataimport_gloloc(basename)

loadpaths

chanexcl = [1,8,14,17,21,25,32,38,43,44,48,49,56,63,64,68,69,73,74,81,82,88,89,94,95,99,107,113,114,119,120,121,125,126,127,128];
chanlocfile = 'GSN-HydroCel-129.sfp';

filenames = dir(sprintf('%s%s*', filepath, basename));

if isempty(filenames)
    error('No files found to import!\n');
end

mfffiles = filenames(logical(cell2mat({filenames.isdir})));
if length(mfffiles) > 1
    error('Expected 1 MFF recording file. Found %d.\n',length(mfffiles));

elseif isempty(mfffiles)
    % check for and import NSF file
    if length(filenames) ~= 1
        error('Expected 1 NSF recording file. Found %d.\n',length(filenames));
    else
        filename = filenames.name;
        fprintf('\nProcessing %s.\n\n', filename);
        EEG = pop_readegi(sprintf('%s%s', filepath, filename));
        for e = 1:length(EEG.event)
            EEG.event(e).codes = {'DUMM',0};
        end
        chanlocpath = which(chanlocfile);
        EEG = fixegilocs(EEG,chanlocpath);
    end
    
else
    filename = mfffiles.name;
    fprintf('\nProcessing %s.\n\n', filename);
    EEG = pop_readegimff(sprintf('%s%s', filepath, filename));
end

EEG = eeg_checkset(EEG);

%%% preprocessing

fprintf('Renaming markers.\n');
for e = 1:length(EEG.event)
    evtype = EEG.event(e).type;
    
    switch evtype
        case 'break cnt'
            stdcount = 0;
            prevdev = 0;
            firstdev = false;
            
        otherwise
            switch evtype
                case 'XXH1'
                    evbase = 'LAX';
                case 'XXH2'
                    evbase = 'LBX';
                case 'XYH1'
                    evbase = 'LAY';
                case 'XYH2'
                    evbase = 'LBY';
                case  {'X1f1','X1s2','X2f1','X2s2','Y1f1','Y1s2','Y2f1','Y2s2','XXR1','XXR2','XYR1','XYR2'}
                    evtype = sprintf('%s1',evbase);
                case {'XXY1','XXY2','XXX1','XXX2'}
                    evtype = sprintf('%s3',evbase);
            end
            EEG.event(e).type = evtype;
            
            switch evtype(1:3)
                case {'LAX','LAY','LBX','LBY','RAX','RAY','RBX','RBY'}
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

fprintf('Removing excluded channels.\n');
EEG = pop_select(EEG,'nochannel',chanexcl);

lpfreq = 20;
fprintf('Low-pass filtering below %dHz...\n',lpfreq);
EEG = pop_eegfilt(EEG, 0, lpfreq, [], [0], 0, 0, 'fir1', 0);
hpfreq = 0.5;
fprintf('High-pass filtering above %dHz...\n',hpfreq);
EEG = pop_eegfilt(EEG, hpfreq, 0, [], [0], 0, 0, 'fir1', 0);


EEG.setname = sprintf('%s_orig',basename);
EEG.filename = sprintf('%s_orig.set',basename);
EEG.filepath = filepath;

fprintf('Saving %s%s.\n', EEG.filepath, EEG.filename);
pop_saveset(EEG,'filename', EEG.filename, 'filepath', EEG.filepath);

