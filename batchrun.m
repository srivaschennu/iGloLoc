function batchrun(subjlist)

loadsubj;

subjlist = subjlists{subjlist};

for s = 1:length(subjlist)
    subjname = subjlist{s};
    
%    dataimport(subjname);
   %epochdata(subjname,1);
   %rejartifacts2([subjname '_epochs'],1,4);
   computeic([subjname '_epochs']);
   %rejectic(subjname);
   %rejartifacts2(subjname,2,1,0,[],1000,500);
   %rejartifacts2(subjname,2,3);
    
    %         ploterp(subjname,{'ls','ld'},[-20 20],1);
    %         saveas(gcf,sprintf('figures/%s_gfp_le.jpg',subjname));
    %         close(gcf);
    %
    %         ploterp(subjname,{'gs','gd'},[-20 20],1);
    %         saveas(gcf,sprintf('figures/%s_gfp_ge.jpg',subjname));
    %         close(gcf);
    %     %
    %     compgfp(subjname,{'ls','ad'});
    %     saveas(gcf,sprintf('figures/%s_ale.jpg',subjname));
    %     close(gcf);
    %
    %     compgfp(subjname,{'gs','ad'});
    %     saveas(gcf,sprintf('figures/%s_age.jpg',subjname));
    %     close(gcf);
    %
    %     compgfp(subjname,{'ac','ad'});
    %     saveas(gcf,sprintf('figures/%s_ae.jpg',subjname));
    %     close(gcf);
    
    %ploterp(subjname,{'ls','ld'},[-15 15],1);
    %ploterp(subjname,{'ls','ad'},[-15 15],1);
    %     ploterp(subjname,{'gs','gd'},[-15 15],1);
    %     ploterp(subjname,{'gs','ad'},[-15 15],1);
    
    %     comperp('trial',subjname,{'ld','ls'},[0.05 0.3]);
    %     figHandles = findall(0,'Type','figure');
    %     for f = 1:length(figHandles)
    %         saveas(figHandles(f),sprintf('figures/%s_local%d.jpg',subjname,f));
    %         close(figHandles(f));
    %     end
    %
    %     comperp('trial',subjname,{'gd','gs'},[0.3 0.6]);
    %     figHandles = findall(0,'Type','figure');
    %     for f = 1:length(figHandles)
    %         saveas(figHandles(f),sprintf('figures/%s_global%d.jpg',subjname,f));
    %         close(figHandles(f));
    %     end
    %
    %     close all
end