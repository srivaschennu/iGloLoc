function EEG = epochdata(basename,icamode)

if ~exist('icamode','var') || isempty(icamode)
    icamode = false;
end
keepica = true;

copyartifacts = false;

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
EEG = pop_epoch(EEG,{},[-1.5 0],'eventindices',selectevents);

EEG = pop_rmbase(EEG, [-1500 -1300]);
EEG = eeg_checkset(EEG);

if ischar(basename)
    EEG.setname = basename;
    EEG.filepath = filepath;
    
    if icamode
        EEG.filename = [basename '_base_epochs.set'];
        oldfilename = [basename '_epochs.set'];
    else
        EEG.filename = [basename '_base.set'];
    end
    
    if icamode == true && keepica == true && exist([EEG.filepath EEG.filename],'file') == 2
        oldEEG = pop_loadset('filepath',EEG.filepath,'filename',oldfilename,'loadmode','info');
        if isfield(oldEEG,'icaweights') && ~isempty(oldEEG.icaweights)
            fprintf('Loading existing ICA info from %s%s.\n',EEG.filepath,oldilename);

            keepchan = [];
            for c = 1:length(EEG.chanlocs)
                if ismember({EEG.chanlocs(c).labels},{oldEEG.chanlocs.labels})
                    keepchan = [keepchan c];
                end
                EEG.chanlocs(c).badchan = 0;
            end
            rejchan = EEG.chanlocs(setdiff(1:length(EEG.chanlocs),keepchan));
            EEG = pop_select(EEG,'channel',keepchan);
            
            EEG.icaact = oldEEG.icaact;
            EEG.icawinv = oldEEG.icawinv;
            EEG.icasphere = oldEEG.icasphere;
            EEG.icaweights = oldEEG.icaweights;
            EEG.icachansind = oldEEG.icachansind;
            EEG.reject.gcompreject = oldEEG.reject.gcompreject;
            if isfield('oldEEG','rejchan')
                EEG.rejchan = oldEEG.rejchan;
            else
                EEG.rejchan = rejchan;
            end
            
        end
    end
    
    fprintf('Saving set %s%s.\n',EEG.filepath,EEG.filename);
    pop_saveset(EEG,'filename', EEG.filename, 'filepath', EEG.filepath);
end