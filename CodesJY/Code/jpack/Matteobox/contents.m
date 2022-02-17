% Matteobox Toolbox.
% Version of 26-October-2001
%
% Matteo Carandini's utilities toolbox for Matlab 5
%
% Started in 1995
%
% GENERIC GRAPHICS
% mergefigs      merges two or more figures
% alphabet       useful for labeling axes
% circle         draws a circle
% errstar        plots a series of points with error bars in both x and y
% fillplot       fills the area between two plots
% supertitle     makes a big title over all subplots
% moveax         changes the position of a list of axes
% matchy         fixes the y scale of a list of axes
% changeunits    expresses axes dims in different units
% disptune       displays experimental data and a tuning curve
% islogspaced	  tries to see if a vector is more linearly spaced or log spaced...
% lognums			useful numbers for logplots
%
% TO MAKE VISUAL STIMULI
% plaidimage		draws a plaid or a grating, useful for talks, papers, posters...
%
% TO FIT ANYTHING
% fitit          minimizes the distance between a model and the data
%
% TO FIND SPIKES AND WORK WITH THEM
% findspikes      finds the spikes in membrane potential traces
% spikehisto      computes cycle histograms of spikes
% ftspikes        Fourier Transform of full/sparse data at a given frequency
%
% FOR PSYCHOPHYSICS
% psycho 			the erf function with two parameters
% rvc 				psychophysical contrast response function R = k c^(m+n)/[sigma^m + c^m]
% tvc					threshold vs. contrast function based on rvc
%	
% TO FIT NEUROPHYSIOLOGICAL DATA
% generictune     sum of two gaussians that meet at the peak, eg to fit frequency tuning
% fitgeneric      fits generictune to the data
% oritune         sum of two gaussians that live on a circle, eg to fit orientation tuning
% fitori          fits oritune to the data
% hyper_ratio     hyperbolic ratio function, eg to fit contrast responses
% fit_hyper_ratio fits hyper_ratio to the data
% expfunc         an exponential decay function
% gaussian        a gaussian
%
% FOR CROSS-PLATFORM ISSUES
% grep           finds the files that contain a certain string
% mac2pc         fixes the end-of-line problem when going from the Mac to the PC
%
% MISCELLANEOUS
% myetime         elapsed time in seconds, ignoring days, months and years
% degdiff 			difference in degrees between two angles
% findmax			finds the position of the maximum in a vector
