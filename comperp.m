function comperp(statmode,subjlist,condlist,latency,varargin)

loadpaths

if ~isempty(varargin) && ~isempty(varargin{1})
    alpha = varargin{1};
else
    alpha = 0.05;
end

if length(varargin) > 1 && ~isempty(varargin{2})
    ttesttail = varargin{2};
else
    ttesttail = 0;
end

load conds.mat

timeshift = 0.6; %seconds

loadsubj

if strcmp(statmode,'trial') && ischar(subjlist)
    %%%% perform single-trial statistics
    subjlist = {subjlist};
    subjcond = condlist;
    
elseif strcmp(statmode,'cond') && isnumeric(subjlist) && length(subjlist) == 1
    %%%% perform within-subject statistics
    subjlist = subjlists{subjlist};
    subjcond = repmat(condlist,length(subjlist),1);
    
elseif strcmp(statmode,'subj') && isnumeric(subjlist) && length(subjlist) == 2
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
else
    error('Invalid combination of statmode and subjlist!');
end

numsubj = length(subjlist);
numcond = size(subjcond,2);

conddata = cell(numsubj,numcond);
tldata = cell(numsubj,numcond);

%% load and prepare individual subject datasets
for s = 1:numsubj
    EEG = pop_loadset('filename', sprintf('%s.set', subjlist{s}), 'filepath', filepath);
    
    % rereference
    %EEG = rereference(EEG,1);
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
        
        if c == numcond
            if conddata{s,1}.trials > conddata{s,2}.trials
                fprintf('Equalising trials in condition %s.\n',subjcond{s,1});
                conddata{s,1} = pop_select(conddata{s,1},'trial',1:conddata{s,2}.trials);
            elseif conddata{s,2}.trials > conddata{s,1}.trials
                fprintf('Equalising trials in condition %s.\n',subjcond{s,2});
                conddata{s,2} = pop_select(conddata{s,2},'trial',1:conddata{s,1}.trials);
            end
        end
    end
end

%% prepare for fieldtrip statistical analysis
cfg = [];
cfg.keeptrials = 'yes';
cfg.feedback = 'textbar';
for s = 1:size(conddata,1)
    for c = 1:size(conddata,2)
        tldata{s,c} = ft_timelockanalysis(cfg, convertoft(conddata{s,c}));
    end
end

%% perform fieldtrip statistics
cfg = [];
cfg.method = 'montecarlo';       % use the Monte Carlo Method to calculate the significance probability
cfg.correctm = 'cluster';
cfg.clusterstatistic = 'maxsum'; % test statistic that will be evaluated under the permutation distribution.

cfg.tail = ttesttail;                    % -1, 1 or 0 (default = 0); one-sided or two-sided test
cfg.clustertail = ttesttail;
if ttesttail == 0
    cfg.alpha = alpha/2;               % alpha level of the permutation test
else
    cfg.alpha = alpha;
end
cfg.clusteralpha = alpha;         % alpha level of the sample-specific test statistic that will be used for thresholding

cfg.numrandomization = 200;      % number of draws from the permutation distribution

cfg.minnbchan = 5;               % minimum number of neighborhood channels that is required for a selected

% prepare_neighbours determines what sensors may form clusters
cfg_neighb.method    = 'distance';
cfg_neighb.neighbourdist = 4;
cfg.neighbours       = ft_prepare_neighbours(cfg_neighb,convertoft(conddata{1,1}));

if strcmp(statmode,'trial')
    
    %single-subject statistics: we will compare potentially different
    %number of trials in the two conditions for this subject.
    ttesttype = 'indepsamplesT';
    
    design = zeros(1,size(tldata{1}.trial,1) + size(tldata{2}.trial,1));
    design(1,1:size(tldata{1}.trial,1)) = 1;
    design(1,size(tldata{1}.trial,1)+1:end)= 2;
    cfg.ivar  = 1;                   % number or list with indices, independent variable(s)
    
    cond1data = tldata{1};
    cond2data = tldata{2};
    
elseif strcmp(statmode,'cond')
    
    %group statistics: we will perform within-subject comparison of subject
    %averages
    ttesttype = 'depsamplesT';
    
    cfg_ga = [];
    cfg_ga.keepindividual = 'yes';
    cond1data = ft_timelockgrandaverage(cfg_ga, tldata{:,1});
    cond2data = ft_timelockgrandaverage(cfg_ga, tldata{:,2});
    cond1data.avg = squeeze(mean(cond1data.individual,1));
    cond2data.avg = squeeze(mean(cond2data.individual,1));
    
    design = zeros(2,2*numsubj);
    design(1,:) = [ones(1,numsubj) ones(1,numsubj)+1];
    design(2,:) = [1:numsubj 1:numsubj];
    cfg.ivar     = 1;
    cfg.uvar     = 2;
    
elseif strcmp(statmode,'subj')
    
    %group statistics: we will perform across-subject comparison of subject
    %averages
    ttesttype = 'indepsamplesT';
    
    cfg_ga = [];
    cfg_ga.keepindividual = 'yes';
    cond1data = ft_timelockgrandaverage(cfg_ga, tldata{1:numsubj1,1});
    cond2data = ft_timelockgrandaverage(cfg_ga, tldata{numsubj1+1:end,1});
    
    if size(tldata,2) > 1
        cond1sub = ft_timelockgrandaverage(cfg_ga, tldata{1:numsubj1,2});
        cond2sub = ft_timelockgrandaverage(cfg_ga, tldata{numsubj1+1:end,2});
        cond1data.individual = cond1data.individual - cond1sub.individual;
        cond2data.individual = cond2data.individual - cond2sub.individual;
    end
    
    cond1data.avg = squeeze(mean(cond1data.individual,1));
    cond2data.avg = squeeze(mean(cond2data.individual,1));
    
    design = zeros(1,numsubj);
    design(1,1:numsubj1) = 1;
    design(1,numsubj1+1:end)= 2;
    cfg.ivar  = 1;                   % number or list with indices, independent variable(s)
end

cfg.design = design;             % design matrix
cfg.statistic = ttesttype;

diffcond = cond1data;
diffcond.avg = cond1data.avg - cond2data.avg;

fprintf('\nComparing conditions using %d-tailed %s test\nat alpha of %.2f between %.2f-%.2f sec.\n\n', ttesttail, ttesttype, alpha, latency);
cfg.latency = latency + timeshift;            % time interval over which the experimental conditions must be compared (in seconds)

cfg.feedback = 'textbar';

[stat] = ft_timelockstatistics(cfg, cond1data, cond2data);
stat.chanlocs = chanlocs;

%% plot significant clusters
if isfield(stat,'posclusters') && ~isempty(stat.posclusters)
    posclustidx = find(cell2mat({stat.posclusters.prob}) <= stat.cfg.alpha);
else
    posclustidx = [];
end

if isfield(stat,'negclusters') && ~isempty(stat.negclusters)
    negclustidx = find(cell2mat({stat.negclusters.prob}) <= stat.cfg.alpha);
else
    negclustidx = [];
end

if ~isempty(posclustidx)
    fprintf('Plotting positive clusters.\n');
    figure('Name','Positive Clusters','Color','white');
    figpos = get(gcf,'Position');
    figpos(3) = figpos(3)*length(posclustidx);
    figpos(4) = figpos(4)*2;
    set(gcf,'Position',figpos);
    
    for p = 1:length(posclustidx)
        clust_t = stat.stat;
        clust_t(~(stat.posclusterslabelmat == posclustidx(p))) = 0;
        [maxval,maxidx] = max(clust_t);
        [~,maxmaxidx] = max(maxval);
        maxchan = maxidx(maxmaxidx);
        maxtime = find(stat.time(maxmaxidx) == diffcond.time);
        
        subplot(2,length(posclustidx),p);
        plotvals = diffcond.avg(:,maxtime);
        topoplot(plotvals,stat.chanlocs, 'maplimits', 'absmax', 'electrodes','labels',...
            'pmask',stat.posclusterslabelmat(:,maxmaxidx)==posclustidx(p));
        colorbar
        title(sprintf('%s - %s @ %d ms (p = %.3f)',condlist{1},condlist{2},...
            round((diffcond.time(maxtime)-timeshift)*1000),stat.posclusters(posclustidx(p)).prob));
        
        subplot(2,length(posclustidx),length(posclustidx)+p);
        plot(diffcond.time-timeshift,diffcond.avg(maxchan,:),'LineWidth',1.5);
        ylim = get(gca,'YLim');
        ylim = ylim*2;
        set(gca,'YLim',ylim);
        set(gca,'XLim',[conddata{1,1}.xmin conddata{1,1}.xmax]-timeshift);
        
        line([diffcond.time(1) diffcond.time(end)]-timeshift,[0 0],'LineWidth',1,'Color','black','LineStyle',':');
        line([0 0],ylim,'LineWidth',1,'Color','black','LineStyle',':');
        line([diffcond.time(maxtime) diffcond.time(maxtime)]-timeshift,ylim,'LineWidth',1.5,'LineStyle','--','Color','black');
        clustwinidx = find(stat.posclusterslabelmat(maxchan,:)==posclustidx(p));
        rectangle('Position',[stat.time(clustwinidx(1))-timeshift ylim(1) ...
            stat.time(clustwinidx(end))-stat.time(clustwinidx(1)) ylim(2)-ylim(1)],'EdgeColor','red','LineWidth',2);
        title(sprintf('%s - %s @ %s',condlist{1},condlist{2},stat.chanlocs(maxchan).labels));
        box on
    end
else
    fprintf('No significant positive clusters found.\n');
end

if ~isempty(negclustidx)
    fprintf('Plotting negative clusters.\n');
    figure('Name','Negative Clusters','Color','white');
    figpos = get(gcf,'Position');
    figpos(3) = figpos(3)*length(negclustidx);
    figpos(4) = figpos(4)*2;
    set(gcf,'Position',figpos);
    
    for p = 1:length(negclustidx)
        clust_t = stat.stat;
        clust_t(~(stat.negclusterslabelmat == negclustidx(p))) = 0;
        [minval,minidx] = min(clust_t);
        [~,minminidx] = min(minval);
        minchan = minidx(minminidx);
        mintime = find(stat.time(minminidx) == diffcond.time);
        
        subplot(2,length(negclustidx),p);
        plotvals = diffcond.avg(:,mintime);
        topoplot(plotvals,stat.chanlocs, 'maplimits', 'absmax', 'electrodes','labels',...
            'pmask',stat.negclusterslabelmat(:,minminidx)==negclustidx(p));
        colorbar
        title(sprintf('%s - %s @ %d ms (p = %.3f)',condlist{1},condlist{2},...
            round((diffcond.time(mintime)-timeshift)*1000),stat.negclusters(negclustidx(p)).prob));
        
        subplot(2,length(negclustidx),length(negclustidx)+p);
        plot(diffcond.time-timeshift,diffcond.avg(minchan,:),'LineWidth',1.5);
        ylim = get(gca,'YLim');
        ylim = ylim*2;
        set(gca,'YLim',ylim);
        set(gca,'XLim',[conddata{1,1}.xmin conddata{1,1}.xmax]-timeshift);
        
        line([diffcond.time(1) diffcond.time(end)]-timeshift,[0 0],'LineWidth',1,'Color','black','LineStyle',':');
        line([0 0],ylim,'LineWidth',1,'Color','black','LineStyle',':');
        line([diffcond.time(mintime) diffcond.time(mintime)]-timeshift,ylim,'LineWidth',1.5,'LineStyle','--','Color','black');
        clustwinidx = find(stat.negclusterslabelmat(minchan,:)==negclustidx(p));
        rectangle('Position',[stat.time(clustwinidx(1))-timeshift ylim(1) ...
            stat.time(clustwinidx(end))-stat.time(clustwinidx(1)) ylim(2)-ylim(1)],'EdgeColor','red','LineWidth',2);
        title(sprintf('%s - %s @ %s',condlist{1},condlist{2},stat.chanlocs(minchan).labels));
        box on
    end
else
    fprintf('No significant negative clusters found.\n');
end