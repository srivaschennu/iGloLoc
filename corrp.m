function stat = corrp(stat,varargin)

param = finputcheck(varargin, {
    'alpha' , 'real' , [], 0.05; ...
    'corrp', 'string', {'none','fdr','cluster'}, 'none'; ...
    'clustsize', 'integer', [], 10; ...
    });

stat.pmask = zeros(size(stat.pprob));
stat.nmask = zeros(size(stat.nprob));

stat.pmask(stat.pprob < param.alpha) = 1;
stat.nmask(stat.nprob < param.alpha) = 1;

if strcmp(param.corrp,'fdr')
    % fdr correction
    corrwin = find(stat.times >= stat.param.latency(1) & stat.times <= stat.param.latency(2));
    [~,stat.pmask(corrwin)] = fdr(stat.pprob(corrwin),param.alpha);
    [~,stat.nmask(corrwin)] = fdr(stat.nprob(corrwin),param.alpha);
    
elseif strcmp(param.corrp,'cluster')
    %cluster-based pvalue correction
    nsigidx = find(stat.pmask == 0);
    for n = 1:length(nsigidx)-1
        if nsigidx(n+1)-nsigidx(n) > 1 && nsigidx(n+1)-nsigidx(n)-1 < param.clustsize
            stat.pmask(nsigidx(n)+1:nsigidx(n+1)-1) = 0;
        end
    end
    
    nsigidx = find(stat.nprob >= param.alpha);
    for n = 1:length(nsigidx)-1
        if nsigidx(n+1)-nsigidx(n) > 1 && nsigidx(n+1)-nsigidx(n)-1 < param.clustsize
            stat.nmask(nsigidx(n)+1:nsigidx(n+1)-1) = 0;
        end
    end
end

%% identfy clusters

stat.pclust = struct([]);
stat.nclust = struct([]);

pstart = 1; nstart = 1;
pclustidx = 0; nclustidx = 0;
for p = 2:length(stat.times)
    if stat.pmask(p) == 1 && stat.pmask(p-1) == 0
        pstart = p;
    elseif (stat.pmask(p) == 0 || p == length(stat.times)) && stat.pmask(p-1) == 1
        pend = p;
        
        pclustidx = pclustidx+1;
        stat.pclust(pclustidx).tstat = mean(stat.valu(pstart:pend-1));
        stat.pclust(pclustidx).prob = mean(stat.pprob(pstart:pend-1));
        stat.pclust(pclustidx).win = [stat.times(pstart) stat.times(pend-1)]-stat.timeshift;
    end
    
    if stat.nmask(p) == 1 && stat.nmask(p-1) == 0
        nstart = p;
    elseif (stat.nmask(p) == 0 || p == length(stat.times)) && stat.nmask(p-1) == 1
        nend = p;
        
        nclustidx = nclustidx+1;
        stat.nclust(nclustidx).tstat = mean(stat.valu(nstart:nend-1));
        stat.nclust(nclustidx).prob = mean(stat.nprob(nstart:nend-1));
        stat.nclust(nclustidx).win = [stat.times(nstart) stat.times(nend-1)]-stat.timeshift;
    end
end

paramlist = fieldnames(param);
for p = 1:length(paramlist)
    stat.param.(paramlist{p}) = param.(paramlist{p});
end
