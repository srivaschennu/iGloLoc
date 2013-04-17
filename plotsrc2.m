function plotsrc2(datalist,varargin)

fontsize = 20;
fontname = 'Helvetica';
linewidth = 2;
timeshift = 0.6;
scalefactor = 10^12;

figure;
figpos = get(gcf,'Position');
figpos(4) = figpos(3)/2;
%figpos(3) = round(figpos(3)*(1.75));
set(gcf,'Position',[figpos(1) figpos(2) figpos(3) figpos(4)]);

colorlist = {
    'local standard'    [0         0    1.0000]
    'local deviant'     [0    0.5000         0]
    'global standard'   [1.0000    0         0]
    'global deviant'    [0    0.7500    0.7500]
    'inter-aural dev.'  [0.7500    0    0.7500]
    'inter-aural ctrl.' [0.7500    0.7500    0]
    'attend tones'      [0    0.5000    0.5000]
    'attend sequences'  [0.5000    0    0.5000]
    'interference'      [0    0.2500    0.7500]
    'early glo. std.'   [0.5000    0.5000    0]
    'late glo. std.'    [0.2500    0.5000    0]
    };

param = finputcheck(varargin, {
    'legendstrings', 'cell', {}, {}; ...
    'legendposition', 'string', {}, 'NorthWest'; ...
    'title','string', {}, ' '; ...
    'ylim', 'real', [], [0 50]; ...
    'plottime','real', [], 0; ...
    });


legendstrings = param.legendstrings;
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

for i = 1:length(datalist)
    data = datalist{i};
%     for s = 1:size(data.F{1},1)
%         data.F{1}(s,:) = detrend(data.F{1}(s,:));
%     end
    plotdata = mean(data.F{1},1);
    
    %remove baseline
    %plotdata = rmbase(plotdata,[],find(data.Time-timeshift >= -0.2 & data.Time-timeshift <= 0));
    plotdata = rmbase(plotdata,[],find(data.Time >= -0.2 & data.Time <= 0));
    
    plot(data.Time-timeshift,plotdata*scalefactor,'LineWidth',linewidth*1.5);
end

set(gca,'YLim',param.ylim);
set(gca,'XLim',[data.Time(1) data.Time(end)]-timeshift,...
    'XTick',data.Time(1)-timeshift:0.2:data.Time(end)-timeshift,...
    'FontName',fontname,'FontSize',fontsize);
legend(legendstrings,'Location',param.legendposition);
line([data.Time(1) data.Time(end)]-timeshift,[0 0],'LineWidth',linewidth,'Color','black','LineStyle',':');
line([-0.60 -0.60],ylim,'LineWidth',linewidth,'Color','black','LineStyle',':');
line([-0.45 -0.45],ylim,'LineWidth',linewidth,'Color','black','LineStyle',':');
line([-0.30 -0.30],ylim,'LineWidth',linewidth,'Color','black','LineStyle',':');
line([-0.15 -0.15],ylim,'LineWidth',linewidth,'Color','black','LineStyle',':');
line([    0     0],ylim,'LineWidth',linewidth,'Color','black','LineStyle',':');
%line([param.plottime param.plottime],ylim,'LineWidth',linewidth','Color','red','LineStyle','--');
xlabel('Time relative to 5th tone (sec)','FontName',fontname,'FontSize',fontsize);
%xlabel(' ','FontName',fontname,'FontSize',fontsize);

ylabel('Activation (pA.m)','FontName',fontname,'FontSize',fontsize);
%ylabel(' ','FontName',fontname,'FontSize',fontsize);

box on
title(param.title,'FontName',fontname,'FontSize',fontsize);

set(gcf,'Color','white','Name',mfilename,'FileName',['figures' filesep 'act_' cell2mat(data.AxesTitle)]);
export_fig(gcf,['figures' filesep 'act_' mfilename '.eps']);
