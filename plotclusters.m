function plotclusters(stat,varargin)

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

param = finputcheck(varargin, {
    'legendstrings', 'cell', {}, stat.condlist; ...
    'legendposition', 'string', {}, 'NorthWest'; ...
    'ylim', 'real', [], [-10 10]; ...
    'title','string', {}, ' '; ...
    });


fontname = 'Helvetica';
fontsize = 20;
linewidth = 2;

%% plot significant clusters

posclustidx = [];
if isfield(stat,'posclusters') && ~isempty(stat.posclusters)
    for cidx = 1:length(stat.posclusters)
        if stat.posclusters(cidx).prob < stat.cfg.alpha && isempty(posclustidx) ...
                || (~isempty(posclustidx) && stat.posclusters(cidx).prob < stat.posclusters(posclustidx).prob)
            posclustidx = cidx;
        end
    end
end

negclustidx = [];
if isfield(stat,'negclusters') && ~isempty(stat.negclusters)
    for cidx = 1:length(stat.negclusters)
        if stat.negclusters(cidx).prob < stat.cfg.alpha && isempty(negclustidx) ...
                || (~isempty(negclustidx) && stat.negclusters(cidx).prob < stat.negclusters(negclustidx).prob)
            negclustidx = cidx;
        end
    end
end

if stat.cfg.tail >= 0
    fprintf('Plotting positive clusters.\n');
    
    figfile = sprintf('figures/%s_%s_%s-%s_pos',stat.statmode,num2str(stat.subjinfo),stat.condlist{1},stat.condlist{2});
    figure('Name',sprintf('%s-%s: Positive Clusters',stat.condlist{1},stat.condlist{2}),'Color','white','FileName',[figfile '.fig']);
    figpos = get(gcf,'Position');
    figpos(4) = figpos(3);
    set(gcf,'Position',figpos);
    
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
    
    clust_t = stat.diffcond.avg(:,find(min(abs(stat.diffcond.time-stat.cfg.latency(1))) == abs(stat.diffcond.time-stat.cfg.latency(1))):...
        find(min(abs(stat.diffcond.time-stat.cfg.latency(2))) == abs(stat.diffcond.time-stat.cfg.latency(2))));
    if ~isempty(posclustidx)
        clust_t(~(stat.posclusterslabelmat == posclustidx)) = 0;
    end
    [maxval,maxidx] = max(clust_t);
    [~,maxmaxidx] = max(maxval);
    maxchan = maxidx(maxmaxidx);
    maxtime = find(stat.time(maxmaxidx) == stat.diffcond.time);
    
    subplot(2,1,1);
    plotvals = stat.diffcond.avg(:,maxtime);
    
    if ~isempty(posclustidx)
        topoplot(plotvals,stat.chanlocs, 'maplimits', 'absmax', 'electrodes','off', 'emarker2',{maxchan,'o','green',14,1},...
            'pmask',stat.posclusterslabelmat(:,maxmaxidx)==posclustidx);
    else
        topoplot(plotvals,stat.chanlocs, 'maplimits', 'absmax', 'electrodes','off', 'emarker2',{maxchan,'o','green',14,1},...
            'numcontour',0);
    end
    
    colorbar('FontName',fontname,'FontSize',fontsize);
    title(param.title,'FontName',fontname,'FontSize',fontsize);
    
    subplot(2,1,2);
    set(gca,'ColorOrder',cat(1,colororder,[0 0 0]));
    hold all;
    
    plot(stat.diffcond.time-stat.timeshift,[stat.diffcond.cond1avg(maxchan,:); stat.diffcond.cond2avg(maxchan,:)]','LineWidth',linewidth*1.5);
    %ylim = get(gca,'YLim');
    %ylim = ylim*2;
    ylim = param.ylim;
    set(gca,'YLim',ylim,'XLim',[stat.diffcond.time(1) stat.diffcond.time(end)]-stat.timeshift,'XTick',stat.diffcond.time(1)-stat.timeshift:0.2:stat.diffcond.time(end)-stat.timeshift,...
        'FontName',fontname,'FontSize',fontsize);
    legend(param.legendstrings,'Location',param.legendposition);
    
    line([stat.diffcond.time(1) stat.diffcond.time(end)]-stat.timeshift,[0 0],'LineWidth',linewidth,'Color','black','LineStyle',':');
    line([-0.60 -0.60],ylim,'LineWidth',linewidth,'Color','black','LineStyle',':');
    line([-0.45 -0.45],ylim,'LineWidth',linewidth,'Color','black','LineStyle',':');
    line([-0.30 -0.30],ylim,'LineWidth',linewidth,'Color','black','LineStyle',':');
    line([-0.15 -0.15],ylim,'LineWidth',linewidth,'Color','black','LineStyle',':');
    line([    0     0],ylim,'LineWidth',linewidth,'Color','black','LineStyle',':');
    line([stat.diffcond.time(maxtime) stat.diffcond.time(maxtime)]-stat.timeshift,ylim,'LineWidth',linewidth,'LineStyle','--','Color','red');
    xlabel('Time relative to 5th tone (sec) ','FontName',fontname,'FontSize',fontsize);
    ylabel('Amplitude (uV)','FontName',fontname,'FontSize',fontsize);
    box off
    if ~isempty(posclustidx)
        clustwinidx = find(maxval);
        %         rectangle('Position',[stat.time(clustwinidx(1))-stat.timeshift ylim(1) ...
        %             stat.time(clustwinidx(end))-stat.time(clustwinidx(1)) ylim(2)-ylim(1)],'LineStyle','--','EdgeColor','black','LineWidth',linewidth);
        line([stat.time(clustwinidx(1)) stat.time(clustwinidx(end))]-stat.timeshift,[0 0],'Color','blue','LineWidth',8);
        title(sprintf('Cluster @ %.3f sec (t = %.2f, p = %.3f)', stat.diffcond.time(maxtime)-stat.timeshift,stat.posclusters(posclustidx).clusterstat,stat.posclusters(posclustidx).prob),...
            'FontName',fontname,'FontSize',fontsize);
    else
        title(sprintf('%.3f sec', stat.diffcond.time(maxtime)-stat.timeshift),'FontName',fontname,'FontSize',fontsize);
    end
    set(gcf,'Color','white');
    export_fig(gcf,[figfile '.eps']);
else
    fprintf('No significant positive clusters found.\n');
end

if stat.cfg.tail <= 0
    fprintf('Plotting negative clusters.\n');
    
    figfile = sprintf('figures/%s_%s_%s-%s_neg',stat.statmode,num2str(stat.subjinfo),stat.condlist{1},stat.condlist{2});
    figure('Name',sprintf('%s-%s: Negative Clusters',stat.condlist{1},stat.condlist{2}),'Color','white','FileName',[figfile '.fig']);
    figpos = get(gcf,'Position');
    figpos(4) = figpos(3);
    set(gcf,'Position',figpos);
    
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
    
    clust_t = stat.diffcond.avg(:,find(min(abs(stat.diffcond.time-stat.cfg.latency(1))) == abs(stat.diffcond.time-stat.cfg.latency(1))):...
        find(min(abs(stat.diffcond.time-stat.cfg.latency(2))) == abs(stat.diffcond.time-stat.cfg.latency(2))));
    if ~isempty(negclustidx)
        clust_t(~(stat.negclusterslabelmat == negclustidx)) = 0;
    end
    [minval,minidx] = min(clust_t);
    [~,minminidx] = min(minval);
    minchan = minidx(minminidx);
    mintime = find(stat.time(minminidx) == stat.diffcond.time);
    
    subplot(2,1,1);
    plotvals = stat.diffcond.avg(:,mintime);
    
    %plot cluster with mask
    if ~isempty(negclustidx)
        topoplot(plotvals,stat.chanlocs, 'maplimits', 'absmax', 'electrodes','off', 'emarker2',{minchan,'o','green',14,1},...
            'pmask',stat.negclusterslabelmat(:,minminidx)==negclustidx);
    else
        topoplot(plotvals,stat.chanlocs, 'maplimits', 'absmax', 'electrodes','off', 'emarker2',{minchan,'o','green',14,1},...
            'numcontour',0);
    end
    
    colorbar('FontName',fontname,'FontSize',fontsize);
    title(param.title,'FontName',fontname,'FontSize',fontsize);
    
    subplot(2,1,2);
    set(gca,'ColorOrder',cat(1,colororder,[0 0 0]));
    hold all;
    
    plot(stat.diffcond.time-stat.timeshift,[stat.diffcond.cond1avg(minchan,:); stat.diffcond.cond2avg(minchan,:)]','LineWidth',linewidth*1.5);
    %ylim = get(gca,'YLim');
    %ylim = ylim*2;
    ylim = param.ylim;
    set(gca,'YLim',ylim,'XLim',[stat.diffcond.time(1) stat.diffcond.time(end)]-stat.timeshift,'XTick',stat.diffcond.time(1)-stat.timeshift:0.2:stat.diffcond.time(end)-stat.timeshift,...
        'FontName',fontname,'FontSize',fontsize);
    legend(param.legendstrings,'Location',param.legendposition);
    line([stat.diffcond.time(1) stat.diffcond.time(end)]-stat.timeshift,[0 0],'LineWidth',linewidth,'Color','black','LineStyle',':');
    line([-0.60 -0.60],ylim,'LineWidth',linewidth,'Color','black','LineStyle',':');
    line([-0.45 -0.45],ylim,'LineWidth',linewidth,'Color','black','LineStyle',':');
    line([-0.30 -0.30],ylim,'LineWidth',linewidth,'Color','black','LineStyle',':');
    line([-0.15 -0.15],ylim,'LineWidth',linewidth,'Color','black','LineStyle',':');
    line([    0     0],ylim,'LineWidth',linewidth,'Color','black','LineStyle',':');
    line([stat.diffcond.time(mintime) stat.diffcond.time(mintime)]-stat.timeshift,ylim,'LineWidth',linewidth,'LineStyle','--','Color','red');
    xlabel('Time relative to 5th tone (sec) ','FontName',fontname,'FontSize',fontsize);
    ylabel('Amplitude (uV)','FontName',fontname,'FontSize',fontsize);
    box off
    if ~isempty(negclustidx)
        clustwinidx = find(minval);
        %         rectangle('Position',[stat.time(clustwinidx(1))-stat.timeshift ylim(1) ...
        %             stat.time(clustwinidx(end))-stat.time(clustwinidx(1)) ylim(2)-ylim(1)],'EdgeColor','black','LineStyle','--','LineWidth',linewidth);
        line([stat.time(clustwinidx(1)) stat.time(clustwinidx(end))]-stat.timeshift,[0 0],'Color','blue','LineWidth',8);
        title(sprintf('Cluster @ %.3f sec (t = %.2f, p = %.3f)', stat.diffcond.time(mintime)-stat.timeshift,stat.negclusters(negclustidx).clusterstat,stat.negclusters(negclustidx).prob),...
            'FontName',fontname,'FontSize',fontsize);
    else
        title(sprintf('%.3f sec', stat.diffcond.time(mintime)-stat.timeshift),'FontName',fontname,'FontSize',fontsize);
    end
    set(gcf,'Color','white');
    export_fig(gcf,[figfile '.eps']);
else
    fprintf('No significant negative clusters found.\n');
end