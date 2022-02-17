function time = txt2dat(filename)

dir_output = dir(fullfile(filename,'*.txt'));
filenames = {dir_output.name};

time = [];
count = 0;
for k = 1:length(filenames)
    tmp_name = filenames{k};
    tline = tmp_name(1:end-4);
    count = count + 1;
    hr = tline(end-14:end-13);
    min = tline(end-11:end-10);
    sec = tline(end-8:end-7);
    msec = tline(end-5:end);
    tmp_time = str2num(hr)*60*60*1e6+str2num(min)*60*1e6+str2num(sec)*1e6+str2num(msec);
    
    if length(time) > 0 && tmp_time < time(end)
        end_index = tmp_end_index+1;
        break
    else
        time = [time,tmp_time];
        tmp_end_index = str2double(tline(end-33:end-28));
    end
end
disp(count)

% fid = fopen(filename);
% if fid == -1
%     fprintf ('\nIncorrect file: %s', fNAME)
%     return;
% end
% 
% time = [];
% %%Scans the entire line in as a string, with spaces (to preserve number info)
% tline = fgetl(fid);
% count = 0;
% while ischar(tline)
%     count = count + 1;
%     disp(count)
%     hr = tline(end-14:end-13);
%     min = tline(end-11:end-10);
%     sec = tline(end-8:end-7);
%     msec = tline(end-5:end);
%     tmp_time = str2num(hr)*60*60*1e6+str2num(min)*60*1e6+str2num(sec)*1e6+str2num(msec);
%     time = [time,tmp_time];
%     tline = fgetl(fid);
% end
% fclose(fid);
time = time - time(1);
time = sort(time,'ascend');
time = time/1e4;
save([filename,'.mat'],"time")
% delete wrong jpg and txt
if ~exist('end_index')
    return
end
for k = end_index:180000
    if exist([filename,'\',filename(end-16:end),'.',num2str(k,'%06d'),'.jpg'],'file')
        delete([filename,'\',filename(end-16:end),'.',num2str(k,'%06d'),'.jpg']);
    end
end

for k = 1:length(filenames)
    tmp_name = filenames{k};
    tline = tmp_name(1:end-4);
    if str2double(tline(end-33:end-28)) > end_index
        delete([filename,'\',filenames{k}])
    end
end
    

end