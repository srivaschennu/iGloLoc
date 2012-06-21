function [stat,gfpdiff] = compgfp(subjlist,condlist,varargin)

loadpaths

load conds.mat

timeshift = 600; %milliseconds

param = finputcheck(varargin, { 'ylim', 'real', [], [0 50]; ...
    'alpha' , 'real' , [], 0.05; ...
    'numrand', 'integer', [], 200; ...
    'corrp', 'string', {'none','fdr','cluster'}, 'cluster'; ...
    'latency', 'real', [], []; ...
    'clustsize', 'integer', [], 10; ...
    'fontsize','integer', [], 16; ...
    });

%% SELECTION OF SUBJECTS AND LOADING OF DATA
loadsubj

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
        fprintf('Condition %s: found %d matching epochs.\n',subjcond{s,c},length(selectepochs));
        
        conddata{s,c} = pop_select(EEG,'trial',selectepochs);
        
    end
end

cond1data = conddata{1}.data;
cond2data = conddata{2}.data;
mergedata = cat(3,conddata{1,1}.data,conddata{1,2}.data);

gfpdiff = zeros(param.numrand+1,conddata{1}.pnts);
h_wait = waitbar(0,'Please wait...');
set(h_wait,'Name',[mfilename ' progress']);

for n = 1:param.numrand+1
    
    if n > 1
        waitbar((n-1)/param.numrand,h_wait,sprintf('Permutation %d...',n-1));
        mergedata = mergedata(:,:,randperm(size(mergedata,3)));
        cond1data = mergedata(:,:,1:size(cond1data,3));
        cond2data = mergedata(:,:,size(cond1data,3)+1:end);
    end
    
    %CALCULATE DIFFERENCE OF GFPs?
    %     [~, cond1gfp] = evalc('eeg_gfp(mean(cond1data,3)'')');
    %     [~, cond2gfp] = evalc('eeg_gfp(mean(cond2data,3)'')');
    %     gfpdiff(n,:) = cond1gfp - cond2gfp;
    
    %CALCULATE GFP OF DIFFERENCES?
    [~, gfpdiff(n,:)] = evalc('eeg_gfp(( mean(cond1data,3) - mean(cond2data,3) )'')');
    
end
close(h_wait);

for p = 1:conddata{1}.pnts
    stat.valu(p) = (gfpdiff(1,p) - mean(gfpdiff(2:end,p)))/std(gfpdiff(2:end,p));
    stat.pprob(p) = sum(gfpdiff(2:end,p) >= gfpdiff(1,p))/param.numrand;
    stat.nprob(p) = sum(gfpdiff(2:end,p) <= gfpdiff(1,p))/param.numrand;
end

if isempty(param.latency)
    param.latency = [0 EEG.times(end)-timeshift];
end

times = conddata{1}.times - timeshift;
corrwin = find(times >= param.latency(1) & times <= param.latency(2));

if strcmp(param.corrp,'fdr')
    % fdr correction
    stat.pmask = zeros(size(stat.pprob));
    [~,stat.pmask(corrwin)] = fdr(stat.pprob(corrwin),param.alpha);
    stat.pprob(~stat.pmask) = 1;
    
    stat.nmask = zeros(size(stat.nprob));
    [~,stat.nmask(corrwin)] = fdr(stat.nprob(corrwin),param.alpha);
    stat.nprob(~stat.nmask) = 1;
    
elseif strcmp(param.corrp,'cluster')
    %cluster-based pvalue correction
    nsigidx = find(stat.pprob >= param.alpha);
    for n = 1:length(nsigidx)-1
        if nsigidx(n+1)-nsigidx(n) > 1 && nsigidx(n+1)-nsigidx(n) < param.clustsize
            stat.pprob(nsigidx(n)+1:nsigidx(n+1)-1) = 1;
        end
    end
    stat.pprob([1:corrwin(1)-1,corrwin(end)+1:end]) = 1;
    
    nsigidx = find(stat.nprob >= param.alpha);
    for n = 1:length(nsigidx)-1
        if nsigidx(n+1)-nsigidx(n) > 1 && nsigidx(n+1)-nsigidx(n) < param.clustsize
            stat.nprob(nsigidx(n)+1:nsigidx(n+1)-1) = 1;
        end
    end
    stat.nprob([1:corrwin(1)-1,corrwin(end)+1:end]) = 1;
end

figure('Name',sprintf('%s-%s',condlist{1},condlist{2}),'Color','white');

subplot(2,1,1);
latpnt = find(EEG.times-timeshift >= param.latency(1) & EEG.times-timeshift <= param.latency(2));
[maxval, maxidx] = max(abs(gfpdiff(1,latpnt)),[],2);
[~, maxmaxidx] = max(maxval);
plotpnt = latpnt(1)-1+maxidx(maxmaxidx);

diffcond = mean(conddata{1}.data,3) - mean(conddata{2}.data,3);
plotvals = diffcond(:,plotpnt);
topoplot(plotvals,chanlocs);
title(sprintf('%d ms',EEG.times(plotpnt)-timeshift),'FontSize',param.fontsize);

subplot(2,1,2);
gfpdiff(1,:) = rmbase(gfpdiff(1,:),[],1:find(EEG.times == 0));
plot((EEG.times(1):1000/EEG.srate:EEG.times(end))-timeshift,gfpdiff(1,:),'LineWidth',2);
set(gca,'XLim',[EEG.times(1) EEG.times(end)]-timeshift,'YLim',param.ylim,'FontSize',param.fontsize);
line([0 0],ylim,'Color','black','LineStyle',':');
line([EEG.times(plotpnt) EEG.times(plotpnt)]-timeshift,ylim,'Color','black','LineWidth',2,'LineStyle','--');
xlabel('Time (ms)','FontSize',param.fontsize);
ylabel('Global field power','FontSize',param.fontsize);

pstart = 1; nstart = 1;
for p = 2:EEG.pnts
    if stat.pprob(p) < param.alpha && stat.pprob(p-1) >= param.alpha
        pstart = p;
    elseif stat.pprob(p) >= param.alpha && stat.pprob(p-1) < param.alpha
        rectangle('Position',[EEG.times(pstart)-timeshift param.ylim(1) ...
            EEG.times(p)-EEG.times(pstart) param.ylim(2)-param.ylim(1)],...
            'EdgeColor','red','LineWidth',2);
    end
    
    % SRIVAS - don't plot negative clusters for now... don't know what they
    % mean
%     if stat.nprob(p) < param.alpha && stat.nprob(p-1) >= param.alpha
%         nstart = p;
%     elseif stat.nprob(p) >= param.alpha && stat.nprob(p-1) < param.alpha
%         rectangle('Position',[EEG.times(nstart)-timeshift param.ylim(1) ...
%             EEG.times(p)-EEG.times(nstart) param.ylim(2)-param.ylim(1)],...
%             'EdgeColor','blue','LineWidth',2);
%     end
end

set(gcf,'Color','white');