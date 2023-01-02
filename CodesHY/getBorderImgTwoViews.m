function [border_side, border_top] = getBorderImgTwoViews(img)
% border_side: vector of length 4, xlim+ylim
% border_top: vector of length 4, xlim+ylim
    if size(img,3) == 3
        img = rgb2gray(img);
    end
    bg = mode(img(:));
    img(img~=bg) = uint8(255);
    img(img==bg) = uint8(0);

    margin = 5;

    for x = 2:size(img,1)-1
        for y = 2:size(img,2)-1
            if img(x,y) == uint8(0)
                x_start = max(x-margin,1);
                x_end = min(x+margin,size(img,1));
                y_start = max(y-margin,1);
                y_end = min(y+margin,size(img,2));            
                if (any(img(x_start:x-1,y)==uint8(255))&&any(img(x+1:x_end,y)==uint8(255)))...
                        || (any(img(x,y_start:y-1)==uint8(255))&&any(img(x,y+1:y_end)==uint8(255)))
                    img(x,y) = uint8(255);
                end
            end
        end
    end

    for x = 2:size(img,1)-1
        for y = 2:size(img,2)-1
            if img(x,y) == uint8(0)
                x_start = max(x-margin,1);
                x_end = min(x+margin,size(img,1));
                y_start = max(y-margin,1);
                y_end = min(y+margin,size(img,2));            
                if (any(img(x_start:x-1,y)==uint8(255))&&any(img(x+1:x_end,y)==uint8(255)))...
                        || (any(img(x,y_start:y-1)==uint8(255))&&any(img(x,y+1:y_end)==uint8(255)))
                    img(x,y) = uint8(255);
                end
            end
        end
    end

    % scan from left to right, only care about top squares
    thres = 0.7;
    flag_start = false;
    border = zeros(size(img,1),4);
    for x = 1:size(img,1)
        if mean(img(x,:))<uint8(255*thres)
            if flag_start
                break
            else
                continue
            end
        else
            flag_start = true;
            temp = zeros(1,4);
            count = 0;
            for y = 2:size(img,2)
                if img(x,y)~=img(x,y-1)
                    count = count+1;
                    if count>4
                        break
                    end
                    if img(x,y) == uint8(255)
                        temp(count) = y;
                    else
                        temp(count) = y-1;
                    end
                end
            end
            border(x,:) = temp;
        end
    end

    % get border_y
    border_y = zeros(1,4);
    for k = 1:4
        border_y(k) = mode(border(border(:,k)>0,k));
    end

    % get border_x
    border_x = zeros(1,2);
    thres = 0.95;

    flag_start = false;
    for x = 1:size(img,1)
        if mean(img(x,[border_y(1):border_y(2),border_y(3):border_y(4)]))>uint8(255*thres)
            if ~flag_start
                flag_start = true;
                border_x(1) = x;
            end
        else
            if flag_start
                border_x(2) = x-1;
                break
            end
        end
    end
    
    border_side = [border_y(1),border_y(2),border_x(1),border_x(2)];
    border_top = [border_y(3),border_y(4),border_x(1),border_x(2)];
end
