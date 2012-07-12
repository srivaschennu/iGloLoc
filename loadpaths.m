[~, hostname] = system('hostname');

if strncmpi(hostname,'hsbpc58',length('hsbpc58'))
    filepath = '/Users/chennu/Data/iGloLoc/';
    chanlocpath = '/Users/chennu/Work/EGI/';
    
elseif strncmpi(hostname,'hsbpc57',length('hsbpc57'))
    filepath = 'D:\Data\iGloLoc\';
    chanlocpath = 'D:\Work\EGI\';
    
else
    %%% SET YOUR OWN PATHS HERE %%%
    filepath = '';
    chanlocpath = '';
end