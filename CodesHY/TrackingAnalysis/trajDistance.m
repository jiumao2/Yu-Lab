function d = trajDistance(x,y,mode)
    % x,y: nx2 matrix
    if nargin <= 2
        mode = 'normal';
    end
    x = x(~isnan(x(:,1)) & ~isnan(x(:,2)),:);
    y = y(~isnan(y(:,1)) & ~isnan(y(:,2)),:);

    d1 = 0;
    for k = 1:size(x,1)
        if strcmp(mode,'fast')
            d_this = min(sum((y-x(k,:)).^2,2));
        else
            d_this = 1e8;
            for j = 1:size(y,1)-1
                p1 = y(j,:);
                p2 = y(j+1,:);
                % Distance from point P to line segment AB
                if dot((x(k,:)-p1),(p1-p2))>=0 % angle PAB >= 90 deg?
                    d_temp = norm(x(k,:)-p1);
                elseif dot((x(k,:)-p2),(p2-p1))>=0 % angle PBA >= 90 deg?
                    d_temp = norm(x(k,:)-p2);
                else % distance from point P to line AB
                    p1x = [(x(k,:)-p1),0];
                    p1p2 = [(p2-p1),0];
                    d_temp = cross(p1x,p1p2)/norm(p1-p2);
                    d_temp = abs(d_temp(3));
                end
                if d_temp < d_this
                    d_this = d_temp;
                end
            end
        end
        d1 = d1+d_this;
    end
    d1 = d1./size(x,1);


    d2 = 0;
    temp = x;
    x = y;
    y = temp;

    for k = 1:size(x,1)
        if strcmp(mode,'fast')
            d_this = min(sum((y-x(k,:)).^2,2));
        else
            d_this = 1e8;
            for j = 1:size(y,1)-1
                p1 = y(j,:);
                p2 = y(j+1,:);
                % Distance from point P to line segment AB
                if dot((x(k,:)-p1),(p1-p2))>=0 % angle PAB >= 90 deg?
                    d_temp = norm(x(k,:)-p1);
                elseif dot((x(k,:)-p2),(p2-p1))>=0 % angle PBA >= 90 deg?
                    d_temp = norm(x(k,:)-p2);
                else % distance from point P to line AB
                    p1x = [(x(k,:)-p1),0];
                    p1p2 = [(p2-p1),0];
                    d_temp = cross(p1x,p1p2)/norm(p1-p2);
                    d_temp = abs(d_temp(3));
                end
                if d_temp < d_this
                    d_this = d_temp;
                end
            end
        end
        d2 = d2+d_this;
    end
    d2 = d2./size(x,1);

    d = min(d1,d2);
    % d = (d1+d2)/2;
end