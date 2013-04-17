function stat = compsrc(subjinfo,condlist,latency,scoutname,varargin)

loadpaths

load conds.mat

timeshift = 0.6; %milliseconds

param = finputcheck(varargin, {
    'alpha' , 'real' , [], 0.05; ...
    'numrand', 'integer', [], 1000; ...
    'ttesttail', 'integer', [-1 0 1], 0; ...
    'testcnv', 'string', {'on','off'},'off'; ...
    'testlat', 'string', {'on','off'},'off'; ...
    });

%% SELECTION OF SUBJECTS AND LOADING OF DATA
loadsubj

if ischar(subjinfo)
    %%%% perform single-trial statistics
    subjlist = {subjinfo};
    subjcond = condlist;
    statmode = 'trial';
    
elseif isnumeric(subjinfo) && length(subjinfo) == 1
    %%%% perform within-subject statistics
    subjlist = subjlists{subjinfo};
    subjcond = repmat(condlist,length(subjlist),1);
    if length(condlist) == 3
        condlist = {sprintf('%s-%s',condlist{1},condlist{3}),sprintf('%s-%s',condlist{2},condlist{3})};
    end
    statmode = 'cond';
    
elseif isnumeric(subjinfo) && length(subjinfo) == 2
    %%%% perform across-subject statistics
    subjlist1 = subjlists{subjinfo(1)};
    subjlist2 = subjlists{subjinfo(2)};
    
    numsubj1 = length(subjlist1);
    numsubj2 = length(subjlist2);
    subjlist = cat(1,subjlist1,subjlist2);
    subjcond = cat(1,repmat(condlist(1),numsubj1,1),repmat(condlist(2),numsubj2,1));
    if length(condlist) == 3
        subjcond = cat(2,subjcond,repmat(condlist(3),numsubj1+numsubj2,1));
        condlist = {sprintf('%s-%s',condlist{1},condlist{3}),sprintf('%s-%s',condlist{2},condlist{3})};
    end
    statmode = 'subj';
end

numsubj = length(subjlist);
numcond = size(subjcond,2);

conddata = cell(numsubj,numcond);

%% load and prepare individual subject datasets

for s = 1:length(subjinfo)
    for c = 1:numcond
        dataname = sprintf('cond_%d_%s_%s',subjinfo(s),subjcond{s,c},scoutname);
        load(dataname);
        eval(sprintf('data = %s;',dataname));
        for subj = 1:size(data.F{1},1)
            subjidx = (s-1)*10+subj;
            %conddata{subjidx,c}.data = detrend(data.F{1}(subj,:));
            conddata{subjidx,c}.data = data.F{1}(subj,:);
            conddata{subjidx,c}.srate = 1/(data.Time(2)-data.Time(1));
            conddata{subjidx,c}.times = data.Time;
            conddata{subjidx,c}.xmin = data.Time(1);
            conddata{subjidx,c}.xmax = data.Time(end);
            conddata{subjidx,c}.pnts = length(data.Time);
            conddata{subjidx,c}.nbchan = 1;
            conddata{subjidx,c}.trials = 1;
            conddata{subjidx,c}.icachansind = [];
            conddata{subjidx,c}.chanlocs(1).labels = scoutname;
            conddata{subjidx,c}.chanlocs(1).X = [];
            %conddata{subjidx,c}.data = rmbase(conddata{subjidx,c}.data,[],find(conddata{subjidx,c}.times-timeshift >= -0.2 & conddata{subjidx,c}.times-timeshift <= 0));
            conddata{subjidx,c}.data = rmbase(conddata{subjidx,c}.data,[],find(conddata{subjidx,c}.times >= -0.2 & conddata{subjidx,c}.times <= 0));
        end
    end
end

chanlocs = conddata{1,1}.chanlocs;

%% prepare for fieldtrip statistical analysis
cfg = [];
cfg.keeptrials = 'yes';
cfg.feedback = 'textbar';
for s = 1:size(conddata,1)
    for c = 1:size(conddata,2)
        ftdata = convertoft(conddata{s,c});
        tldata{s,c} = ft_timelockanalysis(cfg, ftdata);
    end
end

%% perform fieldtrip statistics
cfg = [];
cfg.method = 'montecarlo';       % use the Monte Carlo Method to calculate the significance probability
cfg.correctm = 'cluster';
cfg.clusterstatistic = 'maxsum'; % test statistic that will be evaluated under the permutation distribution.

cfg.tail = param.ttesttail;                    % -1, 1 or 0 (default = 0); one-sided or two-sided test
cfg.clustertail = param.ttesttail;
if param.ttesttail == 0
    cfg.alpha = param.alpha/2;               % alpha level of the permutation test
else
    cfg.alpha = param.alpha;
end
cfg.clusteralpha = param.alpha;         % alpha level of the sample-specific test statistic that will be used for thresholding

cfg.numrandomization = param.numrand;      % number of draws from the permutation distribution

cfg.neighbours = [];
cfg.minnbchan = 0;               % minimum number of neighborhood channels that is required for a selected

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
    cond1data.avg = squeeze(mean(cond1data.individual,1))';
    cond2data.avg = squeeze(mean(cond2data.individual,1))';
    
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
    
    cond1data.avg = squeeze(mean(cond1data.individual,1))';
    cond2data.avg = squeeze(mean(cond2data.individual,1))';
    
    design = zeros(1,numsubj);
    design(1,1:numsubj1) = 1;
    design(1,numsubj1+1:end)= 2;
    cfg.ivar  = 1;                   % number or list with indices, independent variable(s)
end

if (strcmp(statmode,'cond') || strcmp(statmode,'subj')) && (strcmp(param.testcnv,'on') || strcmp(param.testlat,'on'))
    timeidx = cond1data.time >= latency(1)+timeshift & cond1data.time <= latency(2)+timeshift;
    for ind = 1:size(cond1data.individual,1)
        for chan = 1:length(cond1data.label)
            if strcmp(param.testcnv,'on')
                summinfo = polyfit(cond1data.time(timeidx),squeeze(cond1data.individual(ind,chan,timeidx))',1);
            elseif strcmp(param.testlat,'on')
                summinfo = calclat(cond1data.time(timeidx),squeeze(cond1data.individual(ind,chan,timeidx))',50);
            end
            cond1data.individual(ind,chan,1) = summinfo(1);
        end
    end
    cond1data.time = 0;
    cond1data.individual = cond1data.individual(:,:,1);
    cond1data.avg = squeeze(mean(cond1data.individual,1))';
    
    timeidx = cond2data.time >= latency(1)+timeshift & cond2data.time <= latency(2)+timeshift;
    for ind = 1:size(cond2data.individual,1)
        for chan = 1:length(cond2data.label)
            if strcmp(param.testcnv,'on')
                summinfo = polyfit(cond2data.time(timeidx),squeeze(cond2data.individual(ind,chan,timeidx))',1);
            elseif strcmp(param.testlat,'on')
                summinfo = calclat(cond2data.time(timeidx),squeeze(cond2data.individual(ind,chan,timeidx))',50);
            end
            cond2data.individual(ind,chan,1) = summinfo(1);
        end
    end
    cond2data.time = 0;
    cond2data.individual = cond2data.individual(:,:,1);
    cond2data.avg = squeeze(mean(cond2data.individual,1))';
end

cfg.design = design;             % design matrix
cfg.statistic = ttesttype;

diffcond = cond1data;
diffcond.cond1avg = cond1data.avg;
diffcond.cond2avg = cond2data.avg;
diffcond.avg = cond1data.avg - cond2data.avg;

fprintf('\nComparing conditions using %d-tailed %s test\nat alpha of %.2f between %.2f-%.2f sec.\n\n', param.ttesttail, ttesttype, param.alpha, latency);
cfg.latency = latency + timeshift;            % time interval over which the experimental conditions must be compared (in seconds)

cfg.feedback = 'textbar';

[stat] = ft_timelockstatistics(cfg, cond1data, cond2data);
stat.chanlocs = chanlocs;

stat.cfg = cfg;
stat.condlist = condlist;
stat.diffcond = diffcond;
stat.timeshift = timeshift;
stat.statmode = statmode;
stat.subjinfo = subjinfo;
stat.param = param;
stat.scoutname = scoutname;

if nargout == 0
    save2file = sprintf('%s_%s_%s-%s_%s.mat',statmode,num2str(subjinfo),condlist{1},condlist{2},scoutname);
    save(save2file,'stat');
end