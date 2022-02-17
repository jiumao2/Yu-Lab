function yy = gaussian(pars,xx) 
% GAUSSIAN	a gaussian 
% 
%		syntax is gaussian([xtop,ytop,y0,sigma],xx) 
%
% 1997 Matteo Carandini
% part of the Matteobox toolbox

xtop 		= pars(1);
ytop 		= pars(2);
y0 		= pars(3);
sigma		= pars(4);

yy = xx;

yy = y0 + (ytop-y0)* exp( -(xx-xtop).^2 / sigma^2 );


