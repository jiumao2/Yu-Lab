% save result to simplified spikes objects
spikes=[];
%  if numel(mua.opt.projectpath)>0
%  spikes.projectpath=mua.opt.projectpath;
%  end;
spikes.sourcefile = features.muafile;
spikes.ts=features.ts;
spikes.cluster_is=features.clusters;
spikes.labelcategories=features.labelcategories;
spikes.clusterlabels=features.clusterlabels;
spikes.sourcechannel=features.sourcechannel;

spikes.Nspikes=mua.Nspikes;

spikes.waveforms=mua.waveforms;
spikes.waveforms_ts=mua.ts_spike;

%outfilename=[spikes.sourcefile(1:end-4),'_clustered.mat'];
locfind1 = strfind(spikes.sourcefile, '\');
locfind2 =  strfind(spikes.sourcefile, '.');

muafile = spikes.sourcefile(locfind1(end)+1:locfind2-1);
if contains(muafile, 'poly')
    outfilename=[features.muafilepath,'poly',num2str(spikes.sourcechannel),'_clustered.mat'];
else
    outfilename=[features.muafilepath,'ch',num2str(spikes.sourcechannel),'_clustered.mat'];
end;


clear dir;
d=dir(outfilename);
if numel(d)>0
    button = questdlg(['overwrite   ',outfilename,'   ?'],'file exists already','Yes','No','Yes');
else
    button='Yes';
end;

if strcmp(button,'Yes')
    
    
    save_text_h = text(-.5,0,'saving... ', 'BackgroundColor',[.7 .9 .7]);
    drawnow;
    
    if ~isfield(s_opt,'dont_save_noise') % bcwrds comp.
        s_opt.dont_save_noise=0;
    end;
    
    if s_opt.dont_save_noise % delete noise from science output file, stop the ram from blowing up too much
        fprintf('discarding %d%% of spikes that were marked noise\n',round(mean(spikes.cluster_is==0)*100));
        ff=find(spikes.cluster_is==0);
        spikes.ts(ff)=[];
        spikes.cluster_is(ff)=[];
        spikes.waveforms(ff,:)=[];
        spikes.Nspikes=numel(spikes.ts);
    end;
    
    
    x=whos('spikes');
    s=round(x.bytes./1024^2); % size in MB
    disp(['saving spikes - ', num2str(s),' MB...']);
    
    save(outfilename,'spikes','-v7.3');
    
    % save simpleclust state so we can just load it again
    % if needed
    
    x=whos('mua');
    s=round(x.bytes./1024^2); % size in MB
    x=whos('features');
    s=s+round(x.bytes./1024^2); % size in MB
    disp(['saving mua input&features  - ', num2str(s),' MB...']);

    if contains(muafile, 'poly')
        outfilename_sc=[features.muafilepath,'poly',num2str(spikes.sourcechannel),'_simpleclust.mat']; 
        mua2wave_clustpoly(num2str(spikes.sourcechannel))
    else
        outfilename_sc=[features.muafilepath,'ch',num2str(spikes.sourcechannel),'_simpleclust.mat'];
         mua2wave_clust(num2str(spikes.sourcechannel))
    end;
    
    save(outfilename_sc,'features','mua','-v7.3');
    
    
    disp(['saved to ',outfilename,' output for using in science']);
    disp(['saved to ',outfilename_sc,' can be loaded with simpleclust']);
    delete(save_text_h);

    % saved to wave_clus file



else
    disp('aborted saving open files');
    
end;
