function plotcnv(stat,statall,varargin)

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
    'title','string', {}, ''; ...
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

if ~isempty(posclustidx)
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
    
    for p = 1:length(posclustidx)
        clust_t = stat.diffcond.avg;
        clust_t(~(stat.posclusterslabelmat == posclustidx(p))) = 0;
        [~,maxchan] = max(clust_t);
        
        subplot(2,length(posclustidx),p);
        plotvals = stat.diffcond.avg;
        
        topoplot(plotvals,stat.chanlocs, 'maplimits', 'absmax', 'electrodes','off', 'emarker2',{maxchan,'o','green',14,1},...
            'pmask',stat.posclusterslabelmat==posclustidx(p));
        
        title(param.title,'FontName',fontname,'FontSize',fontsize);
        colorbar('FontName',fontname,'FontSize',fontsize);
        
        subplot(2,length(posclustidx),length(posclustidx)+p);
        set(gca,'ColorOrder',cat(1,colororder,[0 0 0]));
        hold all;
        
        plot(statall.diffcond.time-statall.timeshift,[statall.diffcond.cond1avg(maxchan,:); statall.diffcond.cond2avg(maxchan,:)]','LineWidth',linewidth*1.5);
        %ylim = get(gca,'YLim');
        %ylim = ylim*2;
        set(gca,'YLim',param.ylim,'XLim',[statall.diffcond.time(1) statall.diffcond.time(end)]-statall.timeshift,'XTick',statall.diffcond.time(1)-statall.timeshift:0.2:statall.diffcond.time(end)-statall.timeshift,...
            'FontName',fontname,'FontSize',fontsize);
        legend(param.legendstrings,'Location',param.legendposition);
        
        line([statall.diffcond.time(1) statall.diffcond.time(end)]-statall.timeshift,[0 0],'LineWidth',linewidth,'Color','black','LineStyle',':');
        line([0 0],ylim,'LineWidth',linewidth,'Color','black','LineStyle',':');
        line([-0.60 -0.60],ylim,'LineWidth',linewidth,'Color','black','LineStyle',':');
        line([-0.45 -0.45],ylim,'LineWidth',linewidth,'Color','black','LineStyle',':');
        line([-0.30 -0.30],ylim,'LineWidth',linewidth,'Color','black','LineStyle',':');
        line([-0.15 -0.15],ylim,'LineWidth',linewidth,'Color','black','LineStyle',':');
        line([    0     0],ylim,'LineWidth',linewidth,'Color','black','LineStyle',':');
        
        timeidx = find(statall.diffcond.time >= statall.cfg.latency(1) & statall.diffcond.time <= statall.cfg.latency(2));
        cond1fit = polyfit(statall.diffcond.time(timeidx),statall.diffcond.cond1avg(maxchan,timeidx),1);
        plot(statall.diffcond.time-statall.timeshift,polyval(cond1fit,statall.diffcond.time),'LineWidth',linewidth,'LineStyle','--','Color',colororder(1,:));
        cond2fit = polyfit(statall.diffcond.time(timeidx),statall.diffcond.cond2avg(maxchan,timeidx),1);
        plot(statall.diffcond.time-statall.timeshift,polyval(cond2fit,statall.diffcond.time),'LineWidth',linewidth,'LineStyle','--','Color',colororder(2,:));
        xlabel('Time relative to 5th tone (sec) ','FontName',fontname,'FontSize',fontsize);
        ylabel('Amplitude (uV)','FontName',fontname,'FontSize',fontsize);
        title(sprintf('CNV diff. = %.2f (t = %.2f, p = %.3f) ',cond1fit(1)-cond2fit(1),...
            stat.posclusters(posclustidx(p)).clusterstat, stat.posclusters(posclustidx(p)).prob), ...
            'FontName',fontname,'FontSize',fontsize);
        box off
    end
    set(gcf,'Color','white');
    export_fig(gcf,[figfile '.eps']);
else
    fprintf('No significant positive clusters found.\n');
end

if ~isempty(negclustidx)
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
    
    for p = 1:length(negclustidx)
        clust_t = stat.diffcond.avg;
        clust_t(~(stat.negclusterslabelmat == negclustidx(p))) = 0;
        [~,minchan] = min(clust_t);
        
        subplot(2,length(negclustidx),p);
        plotvals = stat.diffcond.avg;
        
        topoplot(plotvals,stat.chanlocs, 'maplimits', 'absmax', 'electrodes','off', 'emarker2',{minchan,'o','green',14,1},...
            'pmask',stat.negclusterslabelmat==negclustidx(p));

        title(param.title,'FontName',fontname,'FontSize',fontsize);
        colorbar('FontName',fontname,'FontSize',fontsize);
        
        subplot(2,length(negclustidx),length(negclustidx)+p);
        set(gca,'ColorOrder',cat(1,colororder,[0 0 0]));
        hold all;
        
        plot(statall.diffcond.time-statall.timeshift,[statall.diffcond.cond1avg(minchan,:); statall.diffcond.cond2avg(minchan,:)]','LineWidth',linewidth*1.5);
        %ylim = get(gca,'YLim');
        %ylim = ylim*2;
        set(gca,'YLim',param.ylim,'XLim',[statall.diffcond.time(1) statall.diffcond.time(end)]-statall.timeshift,'XTick',statall.diffcond.time(1)-statall.timeshift:0.2:statall.diffcond.time(end)-statall.timeshift,...
            'FontName',fontname,'FontSize',fontsize);
        legend(param.legendstrings,'Location',param.legendposition);
        line([statall.diffcond.time(1) statall.diffcond.time(end)]-statall.timeshift,[0 0],'LineWidth',linewidth,'Color','black','LineStyle',':');
        line([0 0],ylim,'LineWidth',linewidth,'Color','black','LineStyle',':');
        line([-0.60 -0.60],ylim,'LineWidth',linewidth,'Color','black','LineStyle',':');
        line([-0.45 -0.45],ylim,'LineWidth',linewidth,'Color','black','LineStyle',':');
        line([-0.30 -0.30],ylim,'LineWidth',linewidth,'Color','black','LineStyle',':');
        line([-0.15 -0.15],ylim,'LineWidth',linewidth,'Color','black','LineStyle',':');
        line([    0     0],ylim,'LineWidth',linewidth,'Color','black','LineStyle',':');
        
        timeidx = find(statall.diffcond.time >= statall.cfg.latency(1) & statall.diffcond.time <= statall.cfg.latency(2));
        cond1fit = polyfit(statall.diffcond.time(timeidx),statall.diffcond.cond1avg(minchan,timeidx),1);
        plot(statall.diffcond.time-statall.timeshift,polyval(cond1fit,statall.diffcond.time),'LineWidth',linewidth,'LineStyle','--','Color',colororder(1,:));
        cond2fit = polyfit(statall.diffcond.time(timeidx),statall.diffcond.cond2avg(minchan,timeidx),1);
        plot(statall.diffcond.time-statall.timeshift,polyval(cond2fit,statall.diffcond.time),'LineWidth',linewidth,'LineStyle','--','Color',colororder(2,:));
        xlabel('Time relative to 5th tone (sec) ','FontName',fontname,'FontSize',fontsize);
        ylabel('Amplitude (uV)','FontName',fontname,'FontSize',fontsize);
        title(sprintf('CNV diff. = %.2f (t = %.2f, p = %.3f) ',cond1fit(1)-cond2fit(1),...
            stat.negclusters(negclustidx(p)).clusterstat, stat.negclusters(negclustidx(p)).prob), ...
            'FontName',fontname,'FontSize',fontsize);
        box off
    end
    set(gcf,'Color','white');
    export_fig(gcf,[figfile '.eps']);
else
    fprintf('No significant negative clusters found.\n');
end