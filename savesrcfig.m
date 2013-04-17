function savesrcfig

fighandles = findobj('Type','Figure');
filepath = '/Users/chennu/Work/iGloLoc/figures';
for f = 1:length(fighandles)
    figh = fighandles(f);
    set(0,'CurrentFigure',figh);
    
    set(gcf,'Color','white');
    %figpos = get(gcf,'Position');
    %set(gcf,'Position',[figpos(1) figpos(2) 500 500]);
    cb_h = findobj(gcf,'tag','Colorbar');
    if ~isempty(cb_h) && f == 1
        set(cb_h,'FontSize',28,'YColor','black');
        cbpos = get(cb_h,'Position');
        set(cb_h,'Position',[cbpos(1)-25 cbpos(2) cbpos(3) cbpos(4)]);
    end
    
    % set(0,'ShowHiddenHandles','on');
    % set(findobj(gcf,'String','pA.m'),'FontSize',20,'Color','black');
    % set(0,'ShowHiddenHandles','off');
    figname = get(gcf,'Name');
    [~,basename] = strtok(figname,' ');
    [~,basename] = strtok(basename,'/');
    basename = strtok(basename,'/');
    addpath('/Users/chennu/MATLAB/export_fig');
    fprintf('Saving %s/%s_%d.eps\n',filepath,basename,f);
    export_fig(gcf,sprintf('%s/%s_%d.eps',filepath,basename,f),'-opengl');
    if ~isempty(cb_h) && f == 1
        export_fig(gcf,[filepath filesep basename '_colorbar.eps']);
    end
end

