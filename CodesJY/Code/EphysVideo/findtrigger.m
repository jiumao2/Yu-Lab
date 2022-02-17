function roi = findtrigger(seqfile, timestamps, idx)

% Jianing Yu
% 4.15.2021
% extract ROI from seqfile. 

if iscell(seqfile)
        [ica, headerInfo] = ReadJpegSEQ(seqfile{1},[1 10]); % ica is image cell array
else
    seqfile = {seqfile};
    [ica, headerInfo] = ReadJpegSEQ(seqfile{1},[1 10]); % ica is image cell array
end;

  if nargin<3
     idx =1;
 end;
 
 % plot a single frame
 
 figure(27); clf,
 set(gcf, 'name', 'side view', 'units', 'centimeters', 'position', [5 5 26 16]);  
 ha1= axes; 
 set(ha1, 'units', 'centimeters', 'position', [1 1 15 15], 'nextplot', 'add', 'xlim',[0 1000], 'ylim', [0 1000], 'ydir','reverse')
  axis off
 
 imageidx = ica{idx, 1};
 
 imagesc(imageidx);
 colormap('gray')
 
 % start to choose a region
 ok=0;
 while ~ok
     roi_selected = drawfreehand();
%      an = input('is it OK?Y/N [Y]', 's')
%      if isempty(an)
%          an = 'Y';
%      end;
%      
%      if strcmp(an, 'Y')
%          ok=1;
%      end;
     ok=1;
 end;
 
 mask = createMask(roi_selected); % this mask determines what pixels are included. this is the mask to use in the future. 
 imageidx_roi = imageidx;
 imageidx_roi(~mask)=NaN;
 ha2= axes;
 set(ha2, 'units', 'centimeters', 'position', [17 1 8 8], 'xlim', [min(roi_selected.Position(:,1)) max(roi_selected.Position(:,1))], 'ylim',[min(roi_selected.Position(:,2)) max(roi_selected.Position(:,2))], 'nextplot', 'add', 'ydir','reverse' )
 imagesc(imageidx_roi)
 axis off
 drawnow
  % derive the pixel value within the selected region
  
  tic
  % find trigger time now
  if length(seqfile)==1;
      roi = zeros(1, length(timestamps));
      for i =1:length(timestamps)
           [ica, ~] = ReadJpegSEQ(seqfile{1}, [i i]); % ica is image cell array
           i_img = ica{1, 1};
           i_img_roi = i_img(mask);
           roi(i) = sum(i_img_roi); 
           
           if rem(i, 100) == 0
               sprintf('%2.0f ms', timestamps(i))
           end;
      end;
      
  else
      roi = cell(1, length(seqfile));
      for k =1:length(seqfile)
          for i =1:length(timestamps{k})
              [ica, ~] = ReadJpegSEQ(seqfile{k}, [i i]); % ica is image cell array
              i_img = ica{1, 1};
              i_img_roi = i_img(mask);
              roi{k}(i) = sum(i_img_roi);
              if rem(i, 100) == 0
                  sprintf('%2.0f ms', timestamps(i))
              end;
          end;
      end 
  end;     
  
  toc

  
  
  figure
  