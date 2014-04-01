function getstat(basename,condlist)

loadpaths

if ischar(condlist)
    condlist = {condlist,'base'};
elseif iscell(condlist) && length(condlist) == 1
    condlist{2} = 'base';
end

load(sprintf('%s/trial_%s_%s-%s_gfp.mat', filepath, basename, condlist{1}, condlist{2}));

fprintf('gfp difference = %.2f.\n',mean(stat.gfpdiff(1,stat.times-stat.timeshift >= stat.param.latency(1) & stat.times-stat.timeshift <= stat.param.latency(2))));

if isfield(stat,'pclust')
    fprintf('t-value = %.2f, p-value = %.3f.\n',mean(cell2mat({stat.pclust.tstat})),...
        mean(cell2mat({stat.pclust.prob})));
else
    fprintf('t-value = 0, p-value = 1.\n');
end
