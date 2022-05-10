function RateOut = PlotDCZEffectSingleCell(datafiles, varargin)
% 12-14-2021
%  PlotDCZEffectSingleCell('times_chdat_meansub4.mat')

clusterid = 1;
DCZtime = 0;
kernelwidth = 1000; % kernel width, in ms
figname = 'DCZEffect';
time_segs=[];

for i =1:2:nargin-1
    switch varargin{i}
        case 'cluster'
            clusterid = varargin{i+1};
        case 'tDCZ'
            DCZtime = varargin{i+1};
        case 'KernelSize'
            kernelwidth = varargin{i+1};
        case 'trange'
            trange = varargin{i+1};
        case 'TimeSegments'
            time_segs =  varargin{i+1};
        case 'filename'
            figname = varargin{i+1};
    end;
end;

tic
raw = load(datafiles{1});
spksort = load(datafiles{2});
toc

% These files will be loaded
%   Temp                    1x1                        8  double               
%   cluster_class      264434x2                  4230944  double               
%   forced             264434x1                   264434  logical              
%   gui_status              1x1                  2116628  struct               
%   inspk              264434x10                21154720  double               
%   ipermut                 1x10000                80000  double               
%   par                     1x1                     8635  struct               
%   spikes             264434x64               135390208  double               
%   spkfile                 1x24                      48  char             

spktimes = spksort.cluster_class(spksort.cluster_class(:, 1)==clusterid,2);
% use spike-density function to smooth the spk train

tspk_true = raw.index; % this is the real time
tspk = [0:length(raw.index)-1]/30; % same length as tspk_true but here is no gap
[~, indspk] = intersect(tspk, round(spktimes));
spktimes_true = round(tspk_true(indspk)); % in ms

spkmat = sparse(1, spktimes_true, 1, 1, spktimes_true(end)); 
tspkmat = [1:length(spkmat)]/1000; % in sec

sdf_unit = sdf(tspkmat, spkmat, kernelwidth);

% resample to 1 sec/sample

tspk_resample = downsample(tspkmat, 100);
sdf_resample   = downsample(sdf_unit, 100);


hf=23;
figure(hf); clf(hf) 
set(gcf, 'unit', 'centimeters', 'position', [2 2 10 5], 'paperpositionmode', 'auto','renderer','Painters')
ha1= axes('unit', 'centimeters', 'position', [2 1 7 3], ...
    'xlim', [tspkmat(1) tspkmat(end)],...
    'nextplot', 'add', 'tickdir', 'out', 'TickLength', [0.0200 0.0250]);
plotshaded(tspk_resample, [zeros(1, length(tspk_resample)); sdf_resample'], 'b');
%  plot(tspkmat(sdf_unit>0), sdf_unit(sdf_unit>0), 'marker', '.',  'color', 'k', 'linestyle', 'none')
line([DCZtime DCZtime], get(ha1, 'ylim'), 'color', 'm', 'linewidth', 2, 'linestyle', ':')
   
xlabel('Time (seconds)');
ylabel('Firing rate (Spk)');
title([datafiles{1} '/unit' num2str(clusterid)])

thisFolder = fullfile(pwd, 'Fig');
if ~exist(thisFolder, 'dir')
    mkdir(thisFolder)
end

tosavename= fullfile(thisFolder,  ['DCZ' figname]);

print (hf,'-dpng', tosavename);
print (hf,'-depsc2', tosavename);

%% compute firing rate 

if ~isempty(time_segs)
    RateOut.Cell = {datafiles{1} clusterid};
    RateOut.TimeSegs = time_segs;
    for i=1:size(time_segs, 1)
        if isnan(time_segs(i, 1))
            RateOut.MeanSpks(i) = NaN;
        else
            RateOut.MeanSpks(i) = mean(sdf_unit(tspkmat>time_segs(i, 1) & tspkmat<time_segs(i, 2)));
        end
    end;
else
    RateOut = [];
end;


%%
function spkout=sdf(tspk, spkin, kernel_width)
% 2019, 2021
% Jianing Yu
% tspk is time, in sec
% spkin takes the form of spike 1 and no spike 0, spkin is a sparse matrix.
% spkout is the kernal product of spkin
% firing rate can be estimated by averaging spkout
% K(t)=exp(-t^2/(2*s^2))/(sqrt(2*pi)*s);
% s is the kernel width, e.g., 10 ms


if nargin<3
    kernel_width=1;
end;

f=round(1/(tspk(2)-tspk(1))); % sampling rate

k=gaussian_kernel(kernel_width/1000, f); % the area under the curve is 1

if size(spkin, 1)~=length(tspk)
    spkin=spkin';  % dim1 spikes, dim2 trial nums
end;

if size(k, 1)<size(k, 2)
    k=k';
end;

spkin2=[];
for ni=1:size(spkin, 2)
    spktemp=full(spkin(:, ni));
    spkin2(:, ni)=conv(spktemp, k, 'same');
end;

spkout=spkin2;