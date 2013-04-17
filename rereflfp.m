function rereflfp(basename)

loadpaths

EEG = pop_loadset('filepath',filepath,'filename',[basename '.set']);

for c = 1:length(EEG.chanlocs)
    chanprefix{c} = EEG.chanlocs(c).labels(1:3);
end

uniqchanprefix = unique(chanprefix);

for c = 1:length(uniqchanprefix)
    fprintf('Re-referencing %s channels.\n',uniqchanprefix{c});
    selchan = find(strncmp(uniqchanprefix{c},{EEG.chanlocs.labels},length(uniqchanprefix{c})));
    EEG.data(selchan,:,:) = reref(EEG.data(selchan,:,:),[]);
end

EEG.saved = 'no';
pop_saveset(EEG,'savemode','resave');