function vmout=remove_transient(vmin, spk)

% remove stupid transient when spikes not occuring

vmblank=ones(1, length(vmin));

for i=1:length(spk)
    vmblank(spk(i)-10000:spk(i)+20000)=0;
end;


    
    
    