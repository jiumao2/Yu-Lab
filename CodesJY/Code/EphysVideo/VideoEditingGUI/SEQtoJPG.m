function SEQtoJPG(fileName,path_jpg,end_reading)
if exist(path_jpg)
    disp('jpg图片已存在');
    return
else
    mkdir(path_jpg)
end

frame_idx = round(end_reading/10);
start = 1;
% dir1 = [path_jpg,'\',fileName(end-24:end-8),'.'];
% for k = start:end_reading
%     if ~exist([dir1,num2str(k,'%06d'),'.jpg'])
%         start = k;
%         break;
%     elseif k == end_reading
%         start = k;
%     end
% end

tic
disp(['start from No. ',num2str(start)])
%parfor i = floor(start/10)+1:frame_idx
parfor i = start:end_reading
    try
 %   frames=[10*(i-1)+1 10*i];
    frames=[i,i];
    ReadJpegSEQ(fileName,frames,path_jpg);
    catch
        disp(i)
        disp('error')
    end
end
toc

% delete abnormal jpg file

end