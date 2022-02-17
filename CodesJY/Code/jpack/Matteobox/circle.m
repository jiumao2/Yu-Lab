function f = circle( ctr, rad, opts )
% CIRCLE draws a circle
%	
%	circle( ctr, rad, opts )
%
%	circle( ctr, rad ) defaults opts to '-'
%
% 1995 Matteo Carandini
% part of the Matteobox toolbox

if nargin == 2, opts = '-'; end

theta = linspace(-pi,pi);

plot( ctr(1)+rad*cos(theta), ctr(2)+rad*sin(theta), opts )
 
