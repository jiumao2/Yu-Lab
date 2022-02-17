%
function [outStruct, meta_data] = exportToMeta(T, contacts)

%% meta-data are generally from T. 


%% Basic things

% definitions
outStruct.cellname=[T.cellNum T.cellCode];

outStruct.timeUnitIds = [1 2 3 4 5];
outStruct.timeUnitNames = {'millisecond','second','minute','hour','day'};

% description
outStruct.animalId = T.mouseName;
outStruct.date = datestr(T.trials{1}.spikesTrial.time); % this is time of experiment start, day-month-year time

% stuff to store in the description hash
outStruct.descrHash.keyNames{1} = 'Behavioral Protocol';
outStruct.descrHash.descr{1} = 'The Solo protocol used to acquire this data';
outStruct.descrHash.value{1} = T.trials{1}.behavTrial.sessionType;

outStruct.descrHash.keyNames{2} = 'Orignial object sourcefile';
outStruct.descrHash.descr{2} = 'session object for the behavior';
[file,folder]=uigetfile;
outStruct.descrHash.value{2} = [folder file];
%
% 	outStruct.descrHash.keyNames{2} = 'Original object sourcefile';
% 	outStruct.descrHash.descr{2} = 'The session object used to get this';
% 	outStruct.descrHash.value{2} = obj.baseFileName;


%% Trial stuff
outStruct.trialTimeUnit = 1; % we use the id from timeUnitIds -- in this case, ms
% trial types: e.g.,  'Go'    'GoStim_constant'    'Nogo'    'NogoStim_constant'
% trialTypeMat: 1-Go, 2-Gostim_constant, ....
% trialOutcome: 'hit', 'correctrejection', 'miss', 'fa'
[outStruct.trialTypeStr, outStruct.trialTypeMat, outStruct.trialOutcome] = identifytrialtypes(T); 
outStruct.trialIds = T.trialNums;
outStruct.trialStartTimes = cellfun(@(x)x.behavTrial.trialStartTime*24*3600, T.trials); % all the start times, for each trial; some strange number but the difference gives inter-trial interval

    % trialPropertiesHash - each value{x} must be same length as obj.trialIds.
    outStruct.trialPropertiesHash.keyNames{1} = 'Water time';
    outStruct.trialPropertiesHash.descr{1} = 'Time of water delivery - in sec';
    outStruct.trialPropertiesHash.value{1} = cellfun(@(x)x.behavTrial.answerLickTime, T.trials, 'uniformoutput', false); % could be a number (time in sec) or empty
    outStruct.trialPropertiesHash.keyNames{2} = 'Lick time';
    outStruct.trialPropertiesHash.descr{2} = 'Lick times of a trial - in sec';
    outStruct.trialPropertiesHash.value{2} =  cellfun(@(x)x.behavTrial.beamBreakTimes, T.trials, 'uniformoutput', false);
    outStruct.trialPropertiesHash.keyNames{3} = 'StimulusPosition';
    outStruct.trialPropertiesHash.descr{3} = 'Where the pole was - in Zaber units';
    outStruct.trialPropertiesHash.value{3} = cellfun(@(x)x.behavTrial.motorPosition, T.trials, 'uniformoutput', false);
    outStruct.trialPropertiesHash.keyNames{4} = 'pinDescentOnsetTime';
    outStruct.trialPropertiesHash.descr{4} = 'When the pin comes - in sec';
    outStruct.trialPropertiesHash.value{4} = cellfun(@(x)x.behavTrial.pinDescentOnsetTime, T.trials, 'uniformoutput', false);
    outStruct.trialPropertiesHash.keyNames{5} = 'pinAscentOnsetTime';
    outStruct.trialPropertiesHash.descr{5} = 'When the pin moves away - in sec';
    outStruct.trialPropertiesHash.value{5} = cellfun(@(x)x.behavTrial.pinAscentOnsetTime, T.trials, 'uniformoutput', false);
    
    %% timeSeriesArrays
    
    % whisker stuff
    wTSA.id = []; % could be 0 1
    wTSA.idStr = {};
    wTSA.idStrDetailed = {}; % blank
    wTSA.valueMatrix = [];
    vmTSA.indStr{1}='Vm';
    vmTSA.indStr{2}='AOM';
    
    
    % this is shared by all whisking variables:
    %
    wTSA.timeUnit = 's';
    [wTSA.time, wTSA.trial, theta,  curv, vmTSA.time, vmTSA.trial, vmTSA.valueMatrix(1, :), vmTSA.valueMatrix(2, :)]= getwhiskertime(T);% wTSA.time is the aligned time, wTSA.trial is the trial numbers for each point
    
    % pull individual variables
    whiskingTSAs = {'whiskerAngleTSA', 'whiskerCurvature'};
    wTSA.id=[1 1];
    
    for wid=1:length(theta)
        wTSA.id=[wTSA.id ones(1, length(whiskingTSAs))*T.trials{1}.whiskerTrial.trajectoryIDs(wid)];
        wTSA.valueMatrix{wid}=[theta{wid}; curv{wid}];
    end;
    
    wTSA.idStr{1}='whisking angle';
    wTSA.indStr{2}='curvature change';
    
	wTSA.sourceFileList = {}; % I could reference mp4s, for isntance
	wTSA.sourceFileIdx = []; % I could reference mp4s frames here
    
    outStruct.timeSeriesArrayHash.keyNames{1} = 'whiskerVars';
    outStruct.timeSeriesArrayHash.descr{1} = 'Angle of whiskers and the curvature (relative) of the whiskers.';
    outStruct.timeSeriesArrayHash.value{1} = wTSA;
    
    % Vm data
    

    outStruct.timeSeriesArrayHash.keyNames{2} = 'Vm';
    outStruct.timeSeriesArrayHash.descr{2} = 'membrane potential';
    outStruct.timeSeriesArrayHash.value{2} = vmTSA;
 


	%% eventSeriesArrays

% 	% bar in reach
%     poleES.id = [];
% 	poleES.idStr = 'Bar-in-reach times';
% 	poleES.idStrDetailed = '';
% 	poleES.type = obj.whiskerBarInReachES.type;
% 	poleES.timeUnit = obj.whiskerBarInReachES.timeUnit;
% 	poleES.eventTimes = obj.whiskerBarInReachES.eventTimes;
% 	poleES.eventTrials = obj.whiskerBarInReachES.eventTrials;
% 	poleES.eventPropertiesHash = []; % blank - nothing to put here
% 
% 	outStruct.eventSeriesArrayHash.keyNames{1} = 'poleInReach';
% 	outStruct.eventSeriesArrayHash.descr{1} = 'times when the pole was accessible to the whiskers.';
% 	outStruct.eventSeriesArrayHash.value{1} = poleES;

% touches

tESA.id = [];
tESA.idStrDetailed = {}; % not needed

tESA.idStr{1} = 'contact on time';
tESA.idStr{2} = 'contact off time';

allcontactsbeg=cell(1, length(length(contacts{1}.tid)));
allcontactsend=cell(1, length(length(contacts{1}.tid)));
allcontacttrialids=cell(1, length(length(contacts{1}.tid)));

for i=1:length(contacts)
    this_trial=T.trials{i}.trialNum;
    for iw=1:length(contacts{i}.tid)
        Tstart(i)=24*3600*T.trials{i}.spikesTrial.time;
        if ~isempty(contacts{i}.contactInds{iw})
            
            contact_begs_time=T.trials{i}.whiskerTrial.time{iw}(contacts{i}.segmentInds{iw}(:, 1))+0.01+Tstart(i);
            contact_ends_time=T.trials{i}.whiskerTrial.time{iw}(contacts{i}.segmentInds{iw}(:, 2))+0.01+Tstart(i);
            contact_trials=this_trial*length(contact_begs_time);
            
            allcontactsbeg{iw}=[allcontactsbeg{iw} contact_begs_time];
            allcontactsend{iw}=[allcontactsend{iw} contact_ends_time];
            allcontacttrialids{iw}=[allcontacttrialids{iw} contact_trials];
        end;
    end;
end;

tESA.eventTimes{1}=allcontactsbeg;
tESA.eventTimes{2}=allcontactsend;
tESA.eventTrials=allcontacttrialids;


% tESA.eventPropertiesHash{ei}.keyNames{1} = 'touchNumberWithinTrial';
% tESA.eventPropertiesHash{ei}.descr{1} = ''; % key is descriptive enough
% tESA.eventPropertiesHash{ei}.value{1} = es.eventPropertiesHash.get('touchNumberWithinTrial');
% tESA.eventPropertiesHash{ei}.keyNames{2} = 'kappaMaxAbsOverTouch';
% tESA.eventPropertiesHash{ei}.descr{2} = ''; % key is descriptive enough
% tESA.eventPropertiesHash{ei}.value{2} = es.eventPropertiesHash.get('kappaMaxAbsOverTouch');


outStruct.eventSeriesArrayHash.keyNames{1} = 'touches';
outStruct.eventSeriesArrayHash.descr{1} = 'times when the pole was touched by whiskers.';
outStruct.eventSeriesArrayHash.value{1} = tESA;


% 	%% and the finish
% 	if (nargin >= 2)
% 		s = outStruct; % just so it is easy to access later on
% 		save(outFile, 's');
% 	end


