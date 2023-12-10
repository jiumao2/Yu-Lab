function [border_side, border_top] = getBorderImgTwoViewsNew(img)
% border_side: vector of length 4, xlim+ylim
% border_top: vector of length 4, xlim+ylim

if size(img,3) == 3
    img = rgb2gray(img);
end
bg = mode(img(:));
img(img~=bg) = uint8(255);
img(img==bg) = uint8(0);

y_start = NaN;
y_end = NaN;

thres = 0.5;
for y = 1:size(img, 1)
    if mean(img(y,:))>uint8(255*thres)
        if isnan(y_start)
            y_start = y;
        end
    else
        if isnan(y_end) && ~isnan(y_start)
            y_end = y;
            break
        end
    end
end

% for side view
x_start_side = NaN;
x_end_side = NaN;
for x = 1:size(img, 2)
    if mean(img(y_start:y_end,x))>uint8(255*thres)
        if isnan(x_start_side)
            x_start_side = x;
        end
    else
        if isnan(x_end_side) && ~isnan(x_start_side)
            x_end_side = x;
            break
        end
    end
    if x == size(img, 2)
        x_end_side = size(img,2);
    end
end

% for top view
x_start_top = NaN;
x_end_top = NaN;
for x = x_end_side+1:size(img, 2)
    if mean(img(y_start:y_end,x))>uint8(255*thres)
        if isnan(x_start_top)
            x_start_top = x;
        end
    else
        if isnan(x_end_top) && ~isnan(x_start_top)
            x_end_top = x;
            break
        end
    end
    if x == size(img, 2)
        x_end_top = size(img,2);
    end
end

border_side = [x_start_side,x_end_side,y_start,y_end];
border_top = [x_start_top,x_end_top,y_start,y_end];
end
