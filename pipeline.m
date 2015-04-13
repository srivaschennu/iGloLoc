function pipeline(basename)

dataimport(basename);
epochdata(basename,1);
rejartifacts2([basename '_epochs'],1,4);
computeic([basename '_epochs']);
rejectic(basename);
rejartifacts2(basename,2,3);

compgfp(basename,{'ld','ls'},'latency',[100 300]);
compgfp(basename,{'ad','ls'},'latency',[100 300]);

compgfp(basename,{'gd','gs'},'latency',[300 600]);
compgfp(basename,{'ad','ac'},'latency',[300 600]);

end