channel = 4;
N = 200;

output = dir(['./Ch',num2str(channel),'_*muA_',num2str(N),'pulses.avi']);
filenames = {output.name};

I = zeros(1,length(filenames));
for k = 1:length(filenames)
    I(k) = str2double(filenames{k}(length(['Ch',num2str(channel),'_'])+1:end-length(['_muA_',num2str(N),'pulses.avi'])+1));
end
I = sort(I,'ascend');

trials = ones(1,length(I));
% trials(I==120)=2;
% trials(I==40)=2;

output_filename = ['./processed/Ch',num2str(channel),'_',num2str(N),'pulses.avi'];
vid_out = VideoWriter(output_filename);
vid_out.FrameRate = 50;
vid_out.open();
for k = 1:length(I)
    vid = VideoReader(['./Ch',num2str(channel),'_',num2str(I(k)),'muA_',num2str(N),'pulses.avi']);
    for j = trials(k)*200+1:trials(k)*200+200
        vid_out.writeVideo(vid.read(j));
    end
end
vid_out.close();



















