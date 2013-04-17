function plotsrc1(data,varargin)

%fontsize = 20;
fontsize = 26;
fontname = 'Helvetica';
linewidth = 2;
timeshift = 0.6;
scalefactor = 10^12;

figure;
figpos = get(gcf,'Position');
figpos(4) = figpos(3);
figpos(3) = round(figpos(3)*(1.75));
%figpos(4) = round(figpos(4)*(0.5));
set(gcf,'Position',[figpos(1) figpos(2) figpos(3)*length(data.F) figpos(4)]);

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
    'legendstrings', 'cell', {}, data.AxesLegend; ...
    'legendposition', 'string', {}, 'NorthWest'; ...
    'title','cell', {}, data.AxesTitle; ...
    'ylim', 'real', [], [0 50]; ...
    'plottime','real', [], 0; ...
    });


for i = 1:length(data.F)
    subplot(1,length(data.F),i);
    
    legendstrings = param.legendstrings{i};
    curcolororder = get(gca,'ColorOrder');
    colororder = zeros(length(legendstrings),3);
    for str = 1:length(legendstrings)
        cidx = strcmp(legendstrings{str},colorlist(:,1));
        if sum(cidx) == 1
            colororder(str,:) = colorlist{cidx,2};
        else
            colororder(str,:) = curcolororder(str,:);
        end
    end
    set(gca,'ColorOrder',colororder);
    hold all
    
%     for s = 1:size(data.F{i},1)
%         data.F{i}(s,:) = detrend(data.F{i}(s,:));
%     end

    %remove baseline
    %data.F{i} = rmbase(data.F{i},[],find(data.Time-timeshift >= -0.2 & data.Time-timeshift <= 0));
    data.F{i} = rmbase(data.F{i},[],find(data.Time >= -0.2 & data.Time <= 0));
    
    plot(data.Time-timeshift,data.F{i}*scalefactor,'LineWidth',linewidth*1.5);
    set(gca,'YLim',param.ylim);
    set(gca,'XLim',[data.Time(1) data.Time(end)]-timeshift,...
        'XTick',data.Time(1)-timeshift:0.2:data.Time(end)-timeshift,...
        'FontName',fontname,'FontSize',fontsize);
    if i == length(data.F)
        legend(legendstrings,'Location',param.legendposition);
    end
    line([data.Time(1) data.Time(end)]-timeshift,[0 0],'LineWidth',linewidth,'Color','black','LineStyle',':');
    line([-0.60 -0.60],ylim,'LineWidth',linewidth,'Color','black','LineStyle',':');
    line([-0.45 -0.45],ylim,'LineWidth',linewidth,'Color','black','LineStyle',':');
    line([-0.30 -0.30],ylim,'LineWidth',linewidth,'Color','black','LineStyle',':');
    line([-0.15 -0.15],ylim,'LineWidth',linewidth,'Color','black','LineStyle',':');
    line([    0     0],ylim,'LineWidth',linewidth,'Color','black','LineStyle',':');
    %line([param.plottime param.plottime],ylim,'LineWidth',linewidth','Color','red','LineStyle','--');
    if i == length(data.F)
        xlabel('Time relative to 5th tone (sec)','FontName',fontname,'FontSize',fontsize);
    end
    %xlabel(' ','FontName',fontname,'FontSize',fontsize);
    
    if i == length(data.F)
        ylabel('Activation (pA.m)','FontName',fontname,'FontSize',fontsize);
    end
    %ylabel(' ','FontName',fontname,'FontSize',fontsize);
    
    box off
    title(param.title{i},'FontName',fontname,'FontSize',fontsize);
    %title(' ','FontName',fontname,'FontSize',fontsize);

    timewin = [-0.6 0.2];
    timeidx = find(data.Time-timeshift >= timewin(1) & data.Time-timeshift <= timewin(2));
    dataslope = zeros(size(data.F{1},1),2);
    for d = 1:size(data.F{1},1)
        dataslope(d,:) = polyfit(data.Time(timeidx),data.F{1}(d,timeidx)*scalefactor,1);
        plot(data.Time-timeshift,polyval(dataslope(d,:),data.Time),...
            'LineWidth',2,'LineStyle','--');
    end
end
set(gcf,'Color','white','Name',data.AxesTitle{1},'FileName',['figures' filesep 'act_' cell2mat(data.AxesTitle)]);
export_fig(gcf,['figures' filesep 'act_' cell2mat(data.AxesTitle) '.eps']);
