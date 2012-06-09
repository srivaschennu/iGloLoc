function EEG = computedip(basename)

loadpaths

if ischar(basename)
    EEG = pop_loadset('filepath',filepath,'filename',[basename '.set'],'loadmode','info');
else
    EEG = basename;
end

EEG.dipfit = [];

EEG = pop_dipfit_settings( EEG, 'hdmfile','/Users/chennu/Work/MATLAB/eeglab/plugins/dipfit2.2/standard_BEM/standard_vol.mat',...
    'coordformat','MNI','mrifile','/Users/chennu/Work/MATLAB/eeglab/plugins/dipfit2.2/standard_BEM/standard_mri.mat',...
    'chanfile','/Users/chennu/Work/MATLAB/eeglab/plugins/dipfit2.2/standard_BEM/elec/standard_1005.elc',...
    'coord_transform',[0.39178 -16.308 -3.9509 0.083606 0.0068181 -1.5702 11.0709 11.4495 11.6497] ,'chansel',1:EEG.nbchan );

% EEG = pop_dipfit_settings( EEG, 'hdmfile','/Users/chennu/Work/MATLAB/eeglab/plugins/dipfit2.2/standard_BESA/standard_BESA.mat',...
%     'coordformat','Spherical','mrifile','/Users/chennu/Work/MATLAB/eeglab/plugins/dipfit2.2/standard_BESA/avg152t1.mat',...
%     'chanfile','/Users/chennu/Work/MATLAB/eeglab/plugins/dipfit2.2/standard_BESA/standard-10-5-cap385.elp',...
%     'coord_transform',[1.961 -0.010485 -5.9649 0.00011539 -0.021554 0.00039285 9.3975 10.805 10.2241] ,'chansel',1:EEG.nbchan );

EEG = pop_multifit(EEG, 1:size(EEG.icaweights,1) ,'threshold',100,'rmout','on');

if ischar(basename)
    EEG.saved = 'no';
    fprintf('Saving %s%s\n',filepath,[basename '.set']);
    pop_saveset(EEG,'filepath',filepath,'filename',[basename '.set']);
end