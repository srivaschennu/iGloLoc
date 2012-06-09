function dataimport(basename)

loadpaths

chanlocfile = 'GSN-HydroCel-129.sfp';

filenames = dir(sprintf('%s%s*.nsf', filepath, basename));

if isempty(filenames)
    dir(sprintf('%s%s*.0*', filepath, basename));
end

if isempty(filenames)
    fprintf('No files found to import!\n');
    return;
end

for fn = 1:length(filenames)
    fprintf('\nProcessing %s.\n\n', filenames(fn).name);
    
    EEG = pop_readegi(sprintf('%s%s', filepath, filenames(fn).name));
    
    if exist('mEEG','var') && isstruct(mEEG)
        mEEG = pop_mergeset(mEEG,EEG);
    else
        mEEG = EEG;
    end
    
    %     EEG.setname = sprintf('%s_%d',basename,fn);
    %     fprintf('Saving %s.set.\n', EEG.setname);
    %     pop_saveset(EEG,'filename', EEG.setname, 'filepath', filepath, 'version','7.3');
end

EEG = mEEG;
clear mEEG

EEG = fixegilocs(EEG,[chanlocpath chanlocfile]);
EEG = eeg_checkset(EEG);

EEG.setname = sprintf('%s_orig',basename);
EEG.filename = sprintf('%s_orig.set',basename);
EEG.filepath = filepath;

fprintf('Saving %s%s.\n', EEG.filepath, EEG.filename);
pop_saveset(EEG,'filename', EEG.filename, 'filepath', EEG.filepath);

