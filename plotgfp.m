function plotgfp(stat,varargin)

if strcmp(stat.condlist{end},'base')
    condlist = stat.condlist(1:end-1);
else
    condlist = stat.condlist;
end

colorlist = {
    'monaural loc. std.'    [0         0    1.0000]
    'monaural loc. dev.'     [0    0.5000         0]
    'monaural glo. std.'   [1.0000    0         0]
    'monaural glo. dev.'    [0    0.7500    0.7500]
    'interaural dev.'  [0.7500    0    0.7500]
    'interaural ctrl.' [0.7500    0.7500    0]
    'attend tones'      [0    0.5000    0.5000]
    'attend sequences'  [0.5000    0    0.5000]
    'interference'      [0    0.2500    0.7500]
    'early glo. std.'   [0.5000    0.5000    0]
    'late glo. std.'    [0.2500    0.5000    0]
    };

param = finputcheck(varargin, { 'ylim', 'real', [], [-5 20]; ...
    'fontsize','integer', [], 26; ...
    'legendstrings', 'cell', {}, condlist; ...
    'legendposition', 'string', {}, 'NorthWest'; ...
    'ttesttail', 'integer', [-1 0 1], 0; ...
    'plotinfo', 'string', {'on','off'}, 'on'; ...
    'plottitle', 'string', {'on','off'}, 'on'; ...
    });

%% figure plotting

fontname = 'Helvetica';
linewidth = 2;

figfile = sprintf('figures/%s_%s_%s-%s_gfp',stat.statmode,num2str(stat.subjinfo),stat.condlist{1},stat.condlist{2});

figure('Name',sprintf('%s-%s',stat.condlist{1},stat.condlist{2}),'Color','white','FileName',[figfile '.fig']);
figpos = get(gcf,'Position');
set(gcf,'Position',[figpos(1) figpos(2) figpos(3) figpos(3)]);

% if isfield(stat,'pclust')
%     latpnt = find(stat.times-stat.timeshift >= stat.pclust(1).win(1) & stat.times-stat.timeshift <= stat.pclust(end).win(2));
% else
    latpnt = find(stat.times-stat.timeshift >= stat.param.latency(1) & stat.times-stat.timeshift <= stat.param.latency(2));
% end

%pick time point at max of condition 1
%[~, maxidx] = max(stat.condgfp(1,latpnt,1),[],2);
%pick time point at max of difference
[~, maxidx] = max(stat.gfpdiff(1,latpnt),[],2);
plotpnt = latpnt(1)-1+maxidx;

for c = 1:length(condlist)
    subplot(2,length(condlist),c);
    plotvals = stat.condavg(:,plotpnt,c);
    topoplot(plotvals,stat.chanlocs);
    if c == 1
        cscale = caxis;
    else
        caxis(cscale);
    end
    title(param.legendstrings{c},'FontSize',param.fontsize,'FontName',fontname);
    cb_h = colorbar('FontSize',param.fontsize);
    if c == 1
        cb_labels = num2cell(get(cb_h,'YTickLabel'),2);
        cb_labels{1} = [cb_labels{1} ' uV'];
        set(cb_h,'YTickLabel',cb_labels);
    end
end


subplot(2,2,3:4);
curcolororder = get(gca,'ColorOrder');
colororder = zeros(length(param.legendstrings),3);
for str = 1:length(param.legendstrings)
    cidx = strcmp(param.legendstrings{str},colorlist(:,1));
    if sum(cidx) == 1
        colororder(str,:) = colorlist{cidx,2};
    else
        colororder(str,:) = curcolororder(str,:);
    end
end

set(gca,'ColorOrder',cat(1,colororder,[0 0 0]));
hold all;

plotdata = squeeze(stat.condgfp(1,:,1:length(condlist)));
%plotdata = stat.gfpdiff(1,:);
%param.legendstrings{end+1} = 'difference';
plot((stat.times(1):1000/stat.srate:stat.times(end))-stat.timeshift,plotdata,'LineWidth',linewidth*1.5);

set(gca,'XLim',[stat.times(1) stat.times(end)]-stat.timeshift,'XTick',stat.times(1)-stat.timeshift:200:stat.times(end)-stat.timeshift,'YLim',param.ylim,...
    'FontSize',param.fontsize,'FontName',fontname);
line([0 0],param.ylim,'Color','black','LineStyle',':','LineWidth',linewidth);
line([stat.times(1) stat.times(end)]-stat.timeshift,[0 0],'Color','black','LineStyle',':','LineWidth',linewidth);
line([stat.times(plotpnt) stat.times(plotpnt)]-stat.timeshift,param.ylim,'Color','red','LineWidth',linewidth,'LineStyle','--');
if strcmp(param.plotinfo,'on')
    xlabel('Time (ms) ','FontSize',param.fontsize,'FontName',fontname);
    ylabel('Global field power ','FontSize',param.fontsize,'FontName',fontname);
else
    xlabel(' ','FontSize',param.fontsize,'FontName',fontname);
    ylabel(' ','FontSize',param.fontsize,'FontName',fontname);
end
legend(param.legendstrings,'Location',param.legendposition);
title(sprintf('%dms', round(stat.times(plotpnt))),'FontSize',param.fontsize,'FontName',fontname);

%% plot clusters

if param.ttesttail >= 0
    if isfield(stat,'pclust')
        for p = 1:length(stat.pclust)
            line([stat.pclust(p).win(1) stat.pclust(p).win(2)],[0 0],'Color','blue','LineWidth',8);
            title(sprintf('%dms\nCluster t = %.2f, p = %.3f', round(stat.times(plotpnt)), stat.pclust(p).tstat, stat.pclust(p).prob),...
                'FontSize',param.fontsize,'FontName',fontname);
        end
    else
        fprintf('No positive clusters found.\n');
    end
end

if param.ttesttail <= 0
    if isfield(stat,'nclust')
        for n = 1:length(stat.nclust)
            line([stat.nclust(p).win(1) stat.nclust(p).win(2)],[0 0],'Color','red','LineWidth',8);
            title(sprintf('Cluster t = %.2f, p = %.3f', stat.nclust(n).tstat, stat.nclust(n).prob),...
                'FontSize',param.fontsize,'FontName',fontname);
        end
    else
        fprintf('No negative clusters found.\n');
    end
    
end

title(sprintf('%dms\nt = %.2f, p = %.3f', round(stat.times(plotpnt)), stat.valu(plotpnt), stat.pprob(plotpnt)),...
    'FontSize',param.fontsize,'FontName',fontname);

    
set(gcf,'Color','white');
%saveas(gcf,[figfile '.fig']);
export_fig(gcf,[figfile '.eps']);
