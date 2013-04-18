function batchrun(subjlist)

loadpaths
loadsubj;

subjlist = subjlists{subjlist};

for s = 1:length(subjlist)
    subjname = subjlist{s};
    
    %    dataimport(subjname);
%     dataimport_maria(subjname);
%     
%     epochdata(subjname,1);
%     rejartifacts2([subjname '_epochs'],1,4,[],[],1000,500);
%     computeic([subjname '_epochs']);
%     rejectic(subjname);
    %rejartifacts2(subjname,2,1,0,[],1000,500);
%     rejartifacts2(subjname,2,1);
    
            ploterp(subjname,{'dev'},'topowin',[100 250]);
            saveas(gcf,sprintf('figures/%s_dev.jpg',subjname));
            close(gcf);
            
            ploterp(subjname,{'std'},'topowin',[100 250]);
            saveas(gcf,sprintf('figures/%s_std.jpg',subjname));
            close(gcf);            
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
    %
    %     batchres{s} = compgfp(subjname,{'gd','gs'},'latency',[300 700],'numrand',200,'clustsize',20);
    %     saveas(gcf,sprintf('figures/%s_gd-gs.jpg',subjname));
    %     close(gcf);
    %load(sprintf('trial_%s_dev-std_early.mat',subjname),'stat');
    %     load(sprintf('trial_%s_dev-std_late.mat',subjname),'stat');
    %     posclustidx = [];
    %     if isfield(stat,'posclusters') && ~isempty(stat.posclusters)
    %         for cidx = 1:length(stat.posclusters)
    %             if isempty(posclustidx) ...
    %                     || (~isempty(posclustidx) && stat.posclusters(cidx).prob < stat.posclusters(posclustidx).prob)
    %                 posclustidx = cidx;
    %             end
    %         end
    %     end
    %
    %     if ~isempty(posclustidx)
    %         clust_t = stat.stat;
    %         clust_t(~(stat.posclusterslabelmat == posclustidx)) = 0;
    %         maxval = max(clust_t);
    %         [maxmaxval,maxmaxidx] = max(maxval);
    %         maxtime = find(stat.time(maxmaxidx) == stat.diffcond.time);
    %         starttime = find(stat.time(find(maxval,1,'first')) == stat.diffcond.time);
    %         stoptime = find(stat.time(find(maxval,1,'last')) == stat.diffcond.time);
    %         batchres(s,1) = stat.diffcond.time(starttime)-stat.timeshift;
    %         batchres(s,2) = stat.diffcond.time(stoptime)-stat.timeshift;
    %         batchres(s,3) = maxmaxval;
    %         batchres(s,4) = stat.diffcond.time(maxtime)-stat.timeshift;
    %         fprintf('%s: found cluster from %.3f-%.3fs peaking with %.1f at %.3fs.\n', subjname, batchres(s,1), batchres(s,2), batchres(s,3), batchres(s,4));
    %     else
    %         fprintf('%s: no positive cluster found.\n',subjname);
    %         batchres(s,:) = NaN;
    %     end

%         EEG = pop_loadset('filepath',filepath,'filename',[subjname '.set'],'loadmode','info');
%         batchres(s,1) = length(EEG.rejchan);
%         batchres(s,2) = length(EEG.rejepoch);

%     EEG = pop_loadset('filepath',filepath,'filename',[subjname '_orig.set']);
%     for e = 1:length(EEG.event)
%         evtype = EEG.event(e).type;
%         
%         switch evtype(1:3)
%             case {'XCL','YCL'}
%                 %do not change any markers in control blocks
%                 
%             case {'LAX','LAY','LBX','LBY','RAX','RAY','RBX','RBY'}
%                 stimtype = str2double(evtype(4));
%                 switch stimtype
%                     case {2,3}
%                         snumidx = strcmp('SNUM',EEG.event(e).codes(:,1)');
%                         if sum(snumidx) ~= 1
%                             error('snum not found!');
%                         end
%                         EEG.event(e).codes = EEG.event(e).codes(~snumidx,:);
%                 end
%         end
%     end
%     EEG.saved = 'no';
%     pop_saveset(EEG,'savemode','resave');
%     epochdata(subjname);
% copyfile(['/Volumes/wbicdata/iGloLoc/' subjname '.set'],[filepath subjname '.set']);
% copyfile(['/Volumes/wbicdata/iGloLoc/' subjname '.fdt'],[filepath subjname '.fdt']);
end

% save(sprintf('batch %s.mat',datestr(now)),'batchres');