for i = [44 52]
    complfp('mechulan_sequences',{'ad','ld'},[0.1 0.2],{sprintf('Gri%d',i)},'ttesttail',-1);
    load(sprintf('trial_mechulan_sequences_ad-ld_Gri%d.mat',i));
    plotlfpclusters(stat,'legendstrings',{'inter-aural dev.','local deviant'},'plotinfo','off')
    
    complfp('mechulan_visual',{'ad','ld'},[0.1 0.2],{sprintf('Gri%d',i)},'ttesttail',-1);
    load(sprintf('trial_mechulan_visual_ad-ld_Gri%d.mat',i));
    plotlfpclusters(stat,'legendstrings',{'inter-aural dev.','local deviant'},'plotinfo','off')
end