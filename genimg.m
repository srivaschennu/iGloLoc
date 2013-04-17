function genimg(subjlist,condlist,varargin)

loadpaths

load conds.mat

timeshift = 600; %milliseconds

param = finputcheck(varargin, { 'ylim', 'real', [], [-12 12]; ...
    'subcond', 'string', {'on','off'}, 'on'; ...
    'topowin', 'real', [], []; ...
    });

%% SELECTION OF SUBJECTS AND LOADING OF DATA

loadsubj;

if ischar(subjlist)
    %%%% perform single-trial statistics
    subjlist = {subjlist};
    subjcond = condlist;
    runmode = 'trial';
    
elseif isnumeric(subjlist) && length(subjlist) == 1
    %%%% perform within-subject statistics
    subjlist = subjlists{subjlist};
    subjcond = repmat(condlist,length(subjlist),1);
    runmode = 'cond';
end

numsubj = length(subjlist);
numcond = size(subjcond,2);

conddata = cell(numsubj,numcond);

%% load and prepare individual subject datasets

for s = 1:numsubj
    EEG = pop_loadset('filename', sprintf('%s.set', subjlist{s}), 'filepath', filepath);
    
    % rereference
    % EEG = rereference(EEG,1);
    %
    %     %%%%% baseline correction relative to 5th tone
    %     bcwin = [-200 0];
    %     bcwin = bcwin+(timeshift*1000);
    %     EEG = pop_rmbase(EEG,bcwin);
    %     %%%%%
    
    for c = 1:numcond
        selectevents = conds.(subjcond{s,c}).events;
        selectsnum = conds.(subjcond{s,c}).snum;
        selectpred = conds.(subjcond{s,c}).pred;
        
        typematches = false(1,length(EEG.epoch));
        snummatches = false(1,length(EEG.epoch));
        predmatches = false(1,length(EEG.epoch));
        for ep = 1:length(EEG.epoch)
            
            epochtype = EEG.epoch(ep).eventtype;
            if iscell(epochtype)
                epochtype = epochtype{cell2mat(EEG.epoch(ep).eventlatency) == 0};
            end
            if sum(strcmp(epochtype,selectevents)) > 0
                typematches(ep) = true;
            end
            
            epochcodes = EEG.epoch(ep).eventcodes;
            if iscell(epochcodes{1,1})
                epochcodes = epochcodes{cell2mat(EEG.epoch(ep).eventlatency) == 0};
            end
            
            snumidx = strcmp('SNUM',epochcodes(:,1)');
            if exist('selectsnum','var') && ~isempty(selectsnum) && sum(snumidx) > 0
                if sum(epochcodes{snumidx,2} == selectsnum) > 0
                    snummatches(ep) = true;
                end
            else
                snummatches(ep) = true;
            end
            
            predidx = strcmp('PRED',epochcodes(:,1)');
            if exist('selectpred','var') && ~isempty(selectpred) && sum(predidx) > 0
                if sum(epochcodes{predidx,2} == selectpred) > 0
                    predmatches(ep) = true;
                end
            else
                predmatches(ep) = true;
            end
        end
        
        selectepochs = find(typematches & snummatches & predmatches);
        fprintf('\nCondition %s: found %d matching epochs.\n',subjcond{s,c},length(selectepochs));
        
        if length(selectepochs) == 0
            fprintf('Skipping %s...\n',subjlist{s});
            continue;
        end
        
        conddata{s,c} = pop_select(EEG,'trial',selectepochs);
        
%         if c == numcond
%             if conddata{s,1}.trials > conddata{s,2}.trials
%                 fprintf('Equalising trials in condition %s.\n',subjcond{s,1});
%                 conddata{s,1} = pop_select(conddata{s,1},'trial',1:conddata{s,2}.trials);
%             elseif conddata{s,2}.trials > conddata{s,1}.trials
%                 fprintf('Equalising trials in condition %s.\n',subjcond{s,2});
%                 conddata{s,2} = pop_select(conddata{s,2},'trial',1:conddata{s,1}.trials);
%             end
%         end
        
        conddata{s,c}.data = mean(conddata{s,c}.data,3);
        conddata{s,c}.trials = 1;
        conddata{s,c}.event = conddata{s,c}.event(1);
        conddata{s,c}.event.type = subjcond{s,c};
        conddata{s,c}.epoch = conddata{s,c}.epoch(1);
        conddata{s,c}.epoch(1).eventtype = subjcond{s,c};
        
S = [];
S.dataset = '/Users/chennu/Work/iGloLoc/temp.set';
S.outfile = '/Users/chennu/Work/iGloLoc/temp.mat';
D = spm_eeg_convert(S);

D = D.chantype(1:D.nchannels,'EEG');

S = [];
S.D = D;
S.task = 'loadeegsens';
S.source = 'locfile';
S.sensfile = '/Users/chennu/Work/iGloLoc/chanlocs.sfp';
D = spm_eeg_prep(S);        
    end
end