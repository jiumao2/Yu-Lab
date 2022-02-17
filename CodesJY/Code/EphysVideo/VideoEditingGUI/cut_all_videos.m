function cut_all_videos(path)
dirOutput=dir(path);
fileNames={dirOutput.name};
for k = 1:length(fileNames)
    tic
    filename = fullfile(path,fileNames{k});
    if isfolder(filename) && ~strcmp(fileNames{k},'.') && ~strcmp(fileNames{k},'..') && ~isfolder([filename,'_cut']) && ~strcmp(filename(end-2:end),'cut')
        filename
        cut_video(filename);
    end
    if isfolder(filename) && ~strcmp(fileNames{k},'.') && ~strcmp(fileNames{k},'..') && strcmp(filename(end-2:end),'cut') && ~isfolder(fullfile(filename,'long'))
        filename
        move_video(filename);
    end
    
    toc
end

end
