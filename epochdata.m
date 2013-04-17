function EEG = epochdata(basename,icamode)

if ~exist('icamode','var') || isempty(icamode)
    icamode = false;
end
keepica = true;

copyartifacts = true;

eventlist = {
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
    'CTL'
    };

loadpaths

if ischar(basename)
    EEG = pop_loadset('filename', [basename '_orig.set'], 'filepath', filepath);
else
    EEG = basename;
end

fprintf('Epoching and baselining.\n');

allevents = {EEG.event.type};
selectevents = [];
for e = 1:length(eventlist)
    selectevents = [selectevents find(strncmp(eventlist{e},allevents,length(eventlist{e})))];
end
EEG = pop_epoch(EEG,{},[-0.2 1.3],'eventindices',selectevents);

EEG = pop_rmbase(EEG, [-200 0]);
EEG = eeg_checkset(EEG);

if ischar(basename)
    EEG.setname = basename;
    EEG.filepath = filepath;
    
    if icamode
        EEG.filename = [basename '_epochs.set'];
    else
        EEG.filename = [basename '.set'];
    end
    
    if icamode == true && keepica == true && exist([EEG.filepath EEG.filename],'file') == 2
        oldEEG = pop_loadset('filepath',EEG.filepath,'filename',EEG.filename,'loadmode','info');
        if isfield(oldEEG,'icaweights') && ~isempty(oldEEG.icaweights)
            fprintf('Loading existing ICA info from %s%s.\n',EEG.filepath,EEG.filename);
            EEG.icaact = oldEEG.icaact;
            EEG.icawinv = oldEEG.icawinv;
            EEG.icasphere = oldEEG.icasphere;
            EEG.icaweights = oldEEG.icaweights;
            EEG.icachansind = oldEEG.icachansind;
            EEG.reject.gcompreject = oldEEG.reject.gcompreject;
        end
    end
    
    if copyartifacts == true && exist([EEG.filepath EEG.filename],'file') == 2
        oldEEG = pop_loadset('filepath',EEG.filepath,'filename',EEG.filename,'loadmode','info');
        EEG.rejchan = oldEEG.rejchan;
        EEG.rejepoch = oldEEG.rejepoch;
        for c = 1:length(EEG.chanlocs)
            EEG.chanlocs(c).badchan = 0;
        end
        fprintf('Found %d bad channels and %d bad trials in existing file.\n', length(EEG.rejchan), length(EEG.rejepoch));
        
        EEG = pop_select(EEG,'nochannel',{EEG.rejchan.labels});
        EEG = pop_select(EEG, 'notrial', EEG.rejepoch);
%         EEG = eeg_interp(EEG, EEG.rejchan);
%         EEG = rereference(EEG,3);
    end
    
    fprintf('Saving set %s%s.\n',EEG.filepath,EEG.filename);
    pop_saveset(EEG,'filename', EEG.filename, 'filepath', EEG.filepath);
end