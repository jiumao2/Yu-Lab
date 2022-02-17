function f = freq( nsamples, duration )
% FREQ frequencies corresponding to the elements of an fft
%
% 	freq(nsamples, duration) returns a vector of frequencies
%	[ 0 1/duration 2/duration ... -1/duration ]
%
% 1995 Matteo Carandini
% part of the Matteobox toolbox


f = [0:floor(nsamples/2) , -floor((nsamples-1)/2):1:-1]/duration;
