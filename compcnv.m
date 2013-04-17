function compcnv(stat)

timeidx = find(stat.times >= stat.param.latency(1) & stat.times <= stat.param.latency(2));

colororder = get(gca,'ColorOrder');
hold all;

condslope = zeros(size(stat.condgfp,1),size(stat.condgfp,3),2);

for n = 1:size(stat.condgfp,1)
    for c = 1:size(stat.condgfp,3)
        condslope(n,c,:) = polyfit(stat.times(timeidx),stat.condgfp(n,timeidx,c),1);
        if n == 1
            plot(stat.times,polyval(squeeze(condslope(n,c,:)),stat.times),...
                'LineWidth',2,'LineStyle','--','Color',colororder(c,:));
        end
    end
end

slopediff = condslope(:,1,1)-condslope(:,2,1);
title(sprintf('Diff. in CNV drifts = %.2f (t = %.2f, p = %.3f)', slopediff(1), ...
    (slopediff(1) - mean(slopediff(2:end)))/(std(slopediff(2:end))/sqrt(length(slopediff)-1)), ...
    sum(slopediff(2:end) < slopediff(1))/(length(slopediff)-1)),'FontName','Helvetica','FontSize',20);

