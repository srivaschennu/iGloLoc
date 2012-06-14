function ploterp(subjlist,condlist,varargin)

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
    
elseif isnumeric(subjlist) && length(subjlist) == 1
    %%%% perform within-subject statistics
    subjlist = subjlists{subjlist};
    subjcond = repmat(condlist,length(subjlist),1);
    
elseif isnumeric(subjlist) && length(subjlist) == 2
    %%%% perform across-subject statistics
    subjlist1 = subjlists{subjlist(1)};
    subjlist2 = subjlists{subjlist(2)};
    
    numsubj1 = length(subjlist1);
    numsubj2 = length(subjlist2);
    subjlist = cat(1,subjlist1,subjlist2);
    subjcond = cat(1,repmat(condlist(1),numsubj1,1),repmat(condlist(2),numsubj2,1));
    if length(condlist) == 3
        subjcond = cat(2,subjcond,repmat(condlist(3),numsubj1+numsubj2,1));
    end
end

numsubj = length(subjlist);
numcond = size(subjcond,2);

conddata = cell(numsubj,numcond);

%% load and prepare individual subject datasets

for s = 1:numsubj
    EEG = pop_loadset('filename', sprintf('%s.set', subjlist{s}), 'filepath', filepath);
    
    % %     % rereference
    % EEG = rereference(EEG,1);
    %
    %     %%%%% baseline correction relative to 5th tone
    %     bcwin = [-200 0];
    %     bcwin = bcwin+(timeshift*1000);
    %     EEG = pop_rmbase(EEG,bcwin);
    %     %%%%%
    
    % THIS ASSUMES THAT ALL DATASETS HAVE SAME NUMBER OF ELECTRODES
    if s == 1
        chanlocs = EEG.chanlocs;
        erpdata = zeros(EEG.nbchan,EEG.pnts,numcond,numsubj);
    end
    
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
        
        conddata{s,c} = pop_select(EEG,'trial',selectepochs);
        
        erpdata(:,:,c,s) = mean(conddata{s,c}.data,3);
    end
end

%% PLOTTING

if strcmp(param.subcond, 'on') && numcond == 2
    for s = 1:size(erpdata,4)
        erpdata(:,:,1,s) = erpdata(:,:,1,s) - erpdata(:,:,2,s);
    end
    erpdata = erpdata(:,:,1,:);
    condlist = {sprintf('%s-%s',condlist{1},condlist{2})};
end

erpdata = mean(erpdata,4);

for c = 1:size(erpdata,3)
    plotdata = erpdata(:,:,c);
    
    if isempty(param.topowin)
        param.topowin = [0 EEG.times(end)-timeshift];
    end
    latpnt = find(EEG.times-timeshift >= param.topowin(1) & EEG.times-timeshift <= param.topowin(2));
    [maxval, maxidx] = max(abs(plotdata(:,latpnt)),[],2);
    [~, maxmaxidx] = max(maxval);
    plottime = EEG.times(latpnt(1)-1+maxidx(maxmaxidx));
    if plottime == EEG.times(end)
        plottime = EEG.times(end-1);
    end
    
    %plot ERP data
    figure('Name',condlist{c});
    timtopo(plotdata,chanlocs,...
        'limits',[EEG.times(1)-timeshift EEG.times(end)-timeshift, param.ylim],...
        'plottimes',plottime-timeshift);
    set(gcf,'Color','white');
end

% gadiff = diffdata{1};
% gadiff.data = erpdata(:,:,2)-erpdata(:,:,1);
% gadiff.setname = sprintf('%s-%s',condlist{2},condlist{1});
% pop_saveset(gadiff,'filepath',filepath,'filename',[gadiff.setname '.set']);