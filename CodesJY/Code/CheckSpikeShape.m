function CheckSpikeShape(chname, clusterid)

load(['times_chdat' chname '.mat']);

%   Temp                   2x1                     16  double               
%   cluster_class      25419x2                 406704  double       
%   forced             25419x1                  25419  logical              
%   gui_status             1x1                 204548  struct               
%   inspk              25419x10               2033520  double               
%   ipermut                1x2000               16000  double               
%   par                    1x1                   9027  struct               
%   spikes             25419x64              13014528  double     
ind_cluster_class = find(cluster_class(:, 1)==clusterid);

spkwave = spikes (cluster_class(:, 1)==clusterid, :);
spktime = cluster_class(cluster_class(:, 1)==clusterid, 2);

meanspkwave =mean(spkwave, 1);
tspk = [1:size(spikes, 2)]/30000;

figure(25); clf

ha1=subplot(2, 2, 1); set(ha1, 'nextplot', 'add');
plot(tspk, spkwave, 'color', [.8 .8 .8], 'linewidth', .2);
hold on
plot(tspk, meanspkwave, 'color', 'k', 'linewidth', 2);
dwave = spkwave - repmat(meanspkwave, size(spkwave, 1), 1);

std_dwave = std(dwave, [], 2);

ha2= subplot(2, 2, [3, 4]); set(ha2, 'nextplot', 'add');
plot(spktime/60*1000, std_dwave, 'k.' )

ha3 = subplot(2, 2, 2);  set(ha2, 'nextplot', 'add');

histogram(std_dwave, [0:10:200])

keepasking =1;
linelower=input('above which line?');
index_over = find(std_dwave>=linelower);

figure(26); clf
hplot1=subplot(1, 2, 1);
plot(tspk, spkwave(index_over, :), 'r');
hplot2=subplot(1, 2, 2);
plot(tspk, spkwave(find(std_dwave<linelower), :), 'color', [.8 .8 .8]);
hold on
plot(tspk, meanspkwave, 'color', 'k', 'linewidth', 2);


reply = input('Do you want more? Y/N [Y]:','s');
if isempty(reply)
    reply = 'Y';
end

if isempty(reply)  ||  strcmp(reply, 'Y')||  strcmp(reply, 'y')
    keepasking =1;
else
    keepasking=0;
end;


while keepasking
    
    linelower=input('above which line?');
    index_over = find(std_dwave>=linelower);
   
    if ~isempty(index_over)
    figure(26); clf;
    ha1=subplot(1, 2, 1); set(ha1, 'nextplot', 'add');
    plot(tspk, spkwave(index_over, :), 'r');
    ha2=subplot(1, 2, 2); set(ha2, 'nextplot', 'add');
    plot(tspk, spkwave(find(std_dwave<linelower), :), 'color', [.8 .8 .8]);
    hold on
    plot(tspk, meanspkwave, 'color', 'k', 'linewidth', 2);
    else
        display('No data')
    end;
    
    reply = input('Do you want more? Y/N [Y]:','s');
    if isempty(reply)
        reply = 'Y';
    end
    
    if isempty(reply)  ||  strcmp(reply, 'Y')||  strcmp(reply, 'y')
        keepasking =1;
    else
        keepasking=0;
    end;
end;

index_over_cluster = ind_cluster_class(index_over);

cluster_class(index_over_cluster, 1)=0;

reply = input('Do you want to save the results? Y/N [Y]:','s');
if isempty(reply)
    reply = 'Y';
end

if isempty(reply)  ||  strcmp(reply, 'Y')||  strcmp(reply, 'y')
    save(['times_chdat' chname '.mat'], 'Temp', 'cluster_class', 'forced', 'gui_status','inspk','ipermut','par','spikes');
end
