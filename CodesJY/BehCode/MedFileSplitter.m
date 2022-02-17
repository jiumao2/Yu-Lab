%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Written 7/11/2013 by Mike McDannald                              %
% Takes standard Med Associates output, splits into separate files %
% and organizes into structures for behavioral analyses            %
% Variables correspond to arrays output by Med                     %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

tic;

clear all;

prompt = {'Enter raw Med file name :'}; % dialog prompt
dlg_title = 'Input'; 
num_lines = 1;
def = {'!YEAR-MO-DA'}; % format of answer to be entered
answer = inputdlg(prompt,dlg_title,num_lines,def); % output
answer = char(answer); %turn into character string
answerString = strcat('C:\Data\Raw',answer); % Point to folder in which data are stored
fileID = fopen(answerString); % open file
a = textscan(fileID,'%q',900000,'delimiter',' '); % read file into a variable using 'space' delimiter
a = a{1,1}; % make each value a cell
a = a(~cellfun(@isempty, a)); % delete empty cells
clear fileID answer answerString def dlg_title num_lines prompt; 

sc0 = {'0:'}; 
sc0 = sc0{1};
sc5 = {'5:'}; 
sc5 = sc5{1};
b = strfind(a,(sc0)); % find extraneous cells containing '0:'
c = strfind(a,(sc5)); % find extraneous cells containing '5:'
info.junk = strcat(b,c); % concatenate the results

clear b c sc0 sc5 ii;

for k = 1:length(a); % empties extraneous cells identified above
   
    if isempty(info.junk{k,1}); % keeps cells that are 'empty'
         a{k,1} = a{k,1};
    else a{k,1} = []; % empties extraneous cells which contain values
        
    end
    
end

clear junk;

a = a(~cellfun(@isempty, a)); % deletes empty cells identified above
b = str2double(a); % converts string to number, allowing us to extract event times
b(end+1,1) = NaN; % allows the program to find the end of the final array

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Following variables are for the partial reinforcement programs %
% PR25(A/B/C)                  %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

    info.subject = find(strcmp(a,'Subject:')); % get subject info location 
    info.experiment = find(strcmp(a,'Experiment:')); % get experiment info location 
    info.group = find(strcmp(a,'Group:')); % get group info location 
    info.program = find(strcmp(a,'MSN:')); % get program info location 

for k = 1:length(info.subject); % make a file containing event times for each subject

    subject = a{(info.subject(k,1))+1,1}; % get subject name
    program = a{(info.program(k,1))+1,1}; % get program name
    
    if strcmp(program(1:4),'PR25'); % find PR25 programs (will ignore all other program types)
    
    info.nosepoke = find(strcmp(a,'F:')); % get nosepoke info location 
    info.reward = find(strcmp(a,'G:')); % get reward info location 
    info.cue100 = find(strcmp(a,'H:')); % get cue100 info location 
    info.cueSPR = find(strcmp(a,'I:')); % get cueSPR info location (Shock trials)
    info.cueNsPR = find(strcmp(a,'J:')); % get cueNsPR info location (No shock trials)
    info.cue0 = find(strcmp(a,'K:')); % get cue0 info location 
    info.s100 = find(strcmp(a,'P:')); % get s100 info location (Shock on cue100 trials)
    info.sPR = find(strcmp(a,'Q:')); % get sPR info location (Shock on cueSPR trials)
    info.nan = isnan(b); % get location of all NaN values
        
    l = info.nosepoke(k,1) + 1; % first nosepoke cell
    u = info.reward(k,1) - 1; % last nosepoke cell
    y = b(l:u,1); % retrieves all values between first and last
    time.nosepoke(:,1) = transpose (y); % create structure for times

    clear l u y; 
    
    l = info.reward(k,1) + 1; % first reward cell
    u = info.cue100(k,1) - 1; % last reward cell
    y = b(l:u,1); % retrieves all values between first and last
    time.reward(:,1) = transpose (y); % create structure for times

    clear l u y;
    
    l = info.cue100(k,1) + 1; % first 100% reinforced cue
    u = info.cueSPR(k,1) - 1; % last 100% reinforced cue
    y = b(l:u,1); % retrieves all values between first and last
    time.cue100(:,1) = transpose (y); % create structure for times

    clear l u y;
    
    l = info.cueSPR(k,1) + 1; % first PR reinforced cue
    u = info.cueNsPR(k,1) - 1; % last PR reinforced cue
    y = b(l:u,1); % retrieves all values between first and last
    time.cueSPR(:,1) = transpose (y); % create structure for times

    clear l u y;
    
    l = info.cueNsPR(k,1) + 1; % first PR omission cue
    u = info.cue0(k,1) - 1; % last PR omission cue
    y = b(l:u,1); % retrieves all values between first and last
    time.cueNsPR(:,1) = transpose (y); % create structure for times

    clear l u y;
   
    l = info.cue0(k,1) + 1; % first 0% cue
    u = info.s100(k,1) - 1; % last 0% cue
    y = b(l:u,1); % retrieves all values between first and last
    time.cue0(:,1) = transpose (y); % create structure for times

    clear l u y;
    
    l = info.s100(k,1) + 1; % first 100% shock delivery
    u = info.sPR(k,1) - 1; % last 100% shock delivery
    y = b(l:u,1); % retrieves all values between first and last
    time.s100(:,1) = transpose (y); % create structure for times

    clear l u y;
    
    l = info.sPR(k,1) + 1; % first PR shock delivery
    u = l+(length(time.cueSPR)-1); % last PR shock delivery
    y = b(l:u,1); % retrieves all values between first and last
    time.sPR(:,1) = transpose (y); % create structure for times

    clear l u y;
    
    filename = ['C:\Data\Split\',subject]; % save each subject's file separately to folder of your choosing
    save(filename, 'time', 'subject', 'program'); % filename and variables to be saved
    
    clear filename time subject program; % house cleaning
    
    else
    
    end
    
end

clear i k a b info; % house cleaning

toc;