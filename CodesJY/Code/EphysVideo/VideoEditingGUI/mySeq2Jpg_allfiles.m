function mySeq2Jpg_allfiles()
fileFolder=fullfile('F:\Pineapple\Pineapple Video');
 
dirOutput=dir(fullfile(fileFolder,'*.seq'));
 
fileNames={dirOutput.name};
for k = 1:length(fileNames)
    tic
    tmp_name = fileNames{k};
    SEQtoJPG('Pineapple',tmp_name);
    disp([num2str(k),' trail: done!']);
    % pause
    toc
end
end