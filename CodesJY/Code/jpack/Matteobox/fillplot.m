function foo = fillplot( x, ly, uy, c )
% FILLPLOT fill the area between two plots
%
% 	fillplot( x, ly, uy, c )
%
% 1997 Matteo Carandini
% part of the Matteobox toolbox

x = x(:);
ly = ly(:);
uy = uy(:);

if length(x) ~= length(ly), error('Bad dimensions in input'); end
if length(x) ~= length(uy), error('Bad dimensions in input'); end

nx = length(x);

xx = [ x; x(nx:-1:1) ];
yy = [ ly; uy(nx:-1:1) ];
foo = fill( xx, yy, c, 'EdgeColor', c );


