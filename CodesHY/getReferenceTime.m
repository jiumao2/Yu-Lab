function output = getReferenceTime(r, t0)
    % return the reference time in milliseconds
    if nargin < 2
        t0 = 0;
    end
    output = datenum(datetime(r.Meta(1).DateTime))*24*60*60*1000-t0;
end