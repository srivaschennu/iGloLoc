function complat(stat)

timewin = [200 700];
timeshift = 600;
pcarea = 50;

timeidx = find(stat.times-timeshift >= timewin(1) & stat.times-timeshift <= timewin(2));

colororder = get(gca,'ColorOrder');
ylimits = ylim;

hold all;

condlat = zeros(size(stat.condgfp,1),size(stat.condgfp,3));

for n = 1:size(stat.condgfp,1)
    for c = 1:size(stat.condgfp,3)
        condlat(n,c) = calclat(stat.times(timeidx),stat.condgfp(n,timeidx,c),pcarea);
        if n == 1
            line([condlat(n,c) condlat(n,c)]-timeshift,ylimits,'LineWidth',2,'LineStyle','--','Color',colororder(c,:));
        end
    end
end

latdiff = condlat(:,1)-condlat(:,2);
title(sprintf('Diff. in %d%% latencies = %.2fms (t = %.2f, p = %.3f)', pcarea, latdiff(1), ...
    (latdiff(1) - mean(latdiff(2:end)))/(std(latdiff(2:end))/sqrt(length(latdiff)-1)), ...
    sum(latdiff(2:end) > latdiff(1))/(length(latdiff)-1)),'FontName','Helvetica','FontSize',20);

function estlat = calclat(times,data,pcarea)
totalarea = sum(abs(data));
pcarea = totalarea * (pcarea/100);

curarea = 0;
for t = 1:length(data)
    curarea = curarea + data(t);
    if curarea >= pcarea
        estlat = times(t);
        return
    end
end
estlat = times(end);

