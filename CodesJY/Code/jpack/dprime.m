function [d,crit] = dprime(pHit,pFA) 
 
% DPRIME  --  Signal-detection theory sensitivity measure. 
% 
%  d = dprime(pHit,pFA) 
%  [d,crit] = dprime(pHit,pFA) 
% 
%  PHIT and PFA are numerical arrays of the same shape. 
%  PHIT is the proportion of "Hits":        P(Yes|Signal) 
%  PFA is the proportion of "False Alarms": P(Yes|Noise) 
%  All numbers involved must be between 0 and 1. 
%  The function calculates the d-prime measure for each <H,FA> pair. 
%  The absolute criterion location CRIT can also be requested. 
%  When the FA rate > miss rate, CRIT<0; when FA < miss rate, CRIT>0. 
%  Requires MATLAB's Statistical Toolbox. 
% 
%  Backward compatibility note (Dec 2007): 
%  In ver 1.0, the second function value was the likelihood ratio BETA 
%  instead of the absolute criterion CRIT. See dprime_ver1_0.m 
% 
%  Equations follow Macmillan & Creelman (2005): 
%  * d' = z(H) - z(F)       % Eq. (1.5) 
%    dprime = norminv(pHit) - norminv(pFA) ; 
%  * c =  -[z(H) + z(F)]/2  % Eq. (2.1) 
%    crit = (norminv(pHit)+norminv(pFA))./(-2) ; 
%  * log(beta) = crit .* dprime   % Eq. (2.6) 
% 
%  References: 
%  * Green, D. M. & Swets, J. A. (1974). Signal Detection Theory and 
%    Psychophysics (2nd Ed.). Huntington, NY: Robert Krieger Publ.Co. 
%  * Macmillan, Neil A. & Creelman, C. Douglas (2005). Detection Theory: 
%    A User's Guide (2nd Ed.). Lawrence Erlbaum Associates. 
%   
%  See also NORMINV, NORMPDF. 
 
% Original coding by Alexander Petrov, Ohio State University. 
% $Revision: 1.1 $  $Date: 2007-12-28 $ 
% 
% Part of the utils toolbox version 1.2 for MATLAB version 5 and up. 
% http://alexpetrov.com/softw/utils/ 
% Copyright (c) Alexander Petrov 1999-2008, http://alexpetrov.com 
% Please read the LICENSE and NO WARRANTY statement in ../utils_license.m 
 
% 1.1 2007-12-28 AP: Introduce CRIT instead of BETA 
% 1.0 2000-09-19 AP: Uses BETA instead of CRIT. Used in all Petrov's 
%                    models and papers prior to Dec 2007 
 
%-- Convert to Z scores, no error checking 
zHit = norminv(pHit) ; 
zFA  = norminv(pFA) ; 
 
%-- Calculate d-prime 
d = zHit - zFA ; 
 
%-- Calculate criterion if requested 
if (nargout > 1) ; crit  = (zHit + zFA) ./ (-2) ; end 
 
%-- Ver. 1.0 legacy: If requested, calculate BETA 
%-- Theorem: log(beta)=crit.*dprime   % Macmillan & Creelman (2005, p. 35) 
%if (nargout > 1) 
%  yHit = normpdf(zHit) ; 
%  yFA  = normpdf(zFA) ; 
%  beta = yHit ./ yFA ; 
%end 
 
%---   Return DPRIME and possibly BETA 
%%%%%% End of file DPRIME.M 