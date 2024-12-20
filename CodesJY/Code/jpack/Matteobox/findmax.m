function ind = findmax(vec)
% FINDMAX finds the maximum value in a vector
%
% ind = findmax(vec)
% (may return a vector if there are more than one)
%
% 2000 Matteo Carandini
% part of the Matteobox toolbox

ind = find( vec(:) == max(vec(:)) );
