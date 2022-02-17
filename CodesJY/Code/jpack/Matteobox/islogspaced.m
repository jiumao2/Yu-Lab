function itslog  =  islogspaced(xx)
% ISLOGSPACED	determines if a vector is log spaced or linear
%
%		islogspaced(xx)
%
%		It is smart about approx spacings. 
%
% 1997 Matteo Carandini
% part of the Matteobox toolbox

% if any(xx==0)
% 	itslog = 0;
%	return;
% end

xx(xx==0) = [];
if isempty(xx), error('Argument contains only zeros'); end

linspaces = diff(unique(xx));
logspaces = diff(unique(log(xx)));

if std(logspaces)/mean(logspaces) > std(linspaces)/mean(linspaces)
	itslog = 0;
else
	itslog = 1;
end

