function plotimage(sessnum,condlist,varargin)

loadovernightsubj

param = finputcheck(varargin, { 'fontsize','integer', [], 20; ...
    });

%% figure plotting

fontname = 'Helvetica';
linewidth = 2;

for s = 1:length(subjlist)
    sessinfo = subjlist{s,sessnum};
    
    if isempty(sessinfo)
        sesscrs(s) = 0;
        finalcrs(s) = 0;
        continue;
    end
    
    basename = sessinfo{1};
    load(sprintf('trial_%s_%s-%s_gfp.mat',basename,condlist{1},condlist{2}));
    
    if ~exist('plotdata','var')
        plotdata = zeros(length(subjlist),length(stat.times));
    end
    
    sesscrs(s) = sessinfo{2};
    finalcrs(s) = subjlist{s,end};
    
    fprintf('%s (%d): ',basename, finalcrs(s)-sesscrs(s));
    if isfield(stat,'pclust')
        fprintf('%.2f\n',stat.pclust.tstat);
    else
        fprintf('%.2f\n',0);
    end
    
    stat.valu(stat.pprob >= stat.param.alpha) = 0;
    plotdata(s,:) = stat.valu;
    
%     for p = 1:length(stat.times)
%         stat.pprob(p) = sum(stat.gfpdiff(2:end,p) >= stat.gfpdiff(1,p))/stat.param.numrand;
%     end
%     stat.pprob = rankpvals(stat.pprob);
%     plotdata(s,:) = stat.pprob;
end

[~,sortidx] = sort(finalcrs-sesscrs);
plotdata = plotdata(sortidx,:);
% sortidx = 1:length(subjlist);

figure;
figpos = get(gcf,'Position');
figpos(3) = figpos(3)*2;
set(gcf,'Position',figpos);

imagesc(stat.times-stat.timeshift,1:length(subjlist),plotdata);
colorbar

set(gca,'YDir','normal','XLim',[stat.times(1) stat.times(end)]-stat.timeshift,...
    'XTick',stat.times(1)-stat.timeshift:200:stat.times(end)-stat.timeshift,...
    'YTick',1:length(subjlist),'YTickLabel',sortidx,...
    'FontSize',param.fontsize,'FontName',fontname);

line([0 0],ylim,'Color','black','LineStyle',':','LineWidth',linewidth);

xlabel('Time (ms) ','FontSize',param.fontsize,'FontName',fontname);
ylabel('Participant ','FontSize',param.fontsize,'FontName',fontname);

box on
figfile = sprintf('figures/img_%s-%s_%d',condlist{1},condlist{2},sessnum);
set(gcf,'Color','white','FileName',figfile);
export_fig(gcf,[figfile '.eps']);

function pvals = rankpvals(pvals)

ranklist = [0.1 0.05 0.01 0.005 0.001 0.0005 0.0001];
pvals(pvals >= ranklist(1)) = 1;
for r = 2:length(ranklist)
    pvals(pvals >= ranklist(r) & pvals < ranklist(r-1)) = ranklist(r-1);
end
pvals(pvals < ranklist(end)) = ranklist(end);