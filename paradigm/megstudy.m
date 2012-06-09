function megstudy

clear all

ts = fix(clock);
datetimestr = sprintf('%02d-%02d-%04d %02d-%02d-%02d',ts(3),ts(2),ts(1),ts(4),ts(5),ts(6));

% directory to store run logs
logdir = 'logs';

load subjid.mat subjid

subjid = subjid+1;

% setup log file
diaryfile = sprintf('%s%s%02d %s.txt',logdir,filesep,subjid,datetimestr);
diary(diaryfile);

runmode = mod(subjid,2);

fprintf('Subject number %d. Session order %d.\n', subjid, runmode);

if runmode == 1
    fprintf('\nRunning ATTEND SEQUENCE and then ATTEND VISUAL session.\n');

    igloloc3('SEQUENCE');
    clear global hd
    
    igloloc3('VISUAL');
    clear global hd

elseif runmode == 0
    fprintf('\nRunning ATTEND VISUAL and then ATTEND SEQUENCE session.\n');
    
    igloloc3('VISUAL');
    clear global hd
    
    igloloc3('SEQUENCE');
    clear global hd
end

save subjid.mat subjid