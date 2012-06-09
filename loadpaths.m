function loadpaths

[~, hostname] = system('hostname');

if strncmpi(hostname,'hsbpc58',length('hsbpc58'))
    assignin('caller','filepath','/Users/chennu/Data/iGloLoc/');
    assignin('caller','chanlocpath','/Users/chennu/Work/EGI/');
elseif strncmpi(hostname,'hsbpc57',length('hsbpc57'))
    assignin('caller','filepath','D:\Data\iGloLoc\');
    assignin('caller','chanlocpath','D:\Work\EGI\');
else
    assignin('caller','filepath','');
    assignin('caller','chanlocpath','');
end