function plothandle = disptune( xx, yy, err, style, blankstim, blankstimcolor )
% DISPTUNE utility to display a tuning curve
%
% 		disptune( xx, yy, err )
%
% 		disptune( xx, yy, err, style )
%
% 		disptune( xx, yy, err, style, blankstim )
%		blankstim is a vector which can only have one nonzero value
%
% 		disptune( xx, yy, err, style, blankstim, blankstimcolor )
%
% 1996 Matteo Carandini
% part of the Matteobox toolbox

if nargin < 4, style = 'ko-'; end
if nargin < 5, blankstim = []; end
if nargin < 6, blankstimcolor = [.5 .5 .5]; end

if length(find(blankstim))>1, error('Max one blankstim please'); end

%------------- find the line style, the color, the mark
% useful because:
% 1 - if you don't have a mark style, plot and errorbar will stupidly join the points
% 2 - the blank line must have same color as rest
[ls,col,mark,msg] = colstyle(style); if ~isempty(msg), error(msg); end
if isempty(mark), mark = 'o'; end	
style = [ls,col,mark];

xx = xx(:);
yy = yy(:);
if length(xx)~=length(yy), error('xx and yy must have same size'); end

holdflag = ishold;

blankpos = find(blankstim);
notblank = setdiff(1:length(xx),blankpos);

lx = min(xx(notblank)); rx = max(xx(notblank)); 
% lx = lx - (rx-lx)/18;
% rx = rx + (rx-lx)/18;
if ~isempty(blankpos)
   if ~isnan(blankstimcolor)
      dy = yy(blankpos)-err(blankpos); uy = yy(blankpos)+err(blankpos);
      % HACK, to ensure good top limit:
      plot([ lx rx ], 1.2*(uy-dy)+[ uy uy ], 'w', 'visible','off'); hold on
      fill([ lx lx rx rx ],[ dy uy uy dy ],blankstimcolor,'edgecolor','none'); hold on;
   end
   % plot([ lx rx ], [ yy(blankpos) yy(blankpos) ], [col '--'],'linewidth',1); 
   plot([ lx rx ], [ yy(blankpos) yy(blankpos) ], '-','color',blankstimcolor,'linewidth',1); 
end
hold on;

[sortx, perm] = sort(xx(notblank));
sorty = yy(notblank(perm));
sorterr = err(notblank(perm));

ee = errorbar( sortx, sorty, sorterr, sorterr, col); 
set(ee(2), 'linestyle','none','marker','none' );
% errorbar( xx(notblank), yy(notblank), err(notblank), err(notblank), style ); 

hold on
plothandle = plot( sortx, sorty, style, 'MarkerSize', 8);
% plothandle = plot( xx(notblank), yy(notblank), style, 'MarkerSize', 8);
set(plothandle,'markerfacecolor',get(plothandle,'color'));
set(plothandle,'markeredgecolor',1-get(gca,'defaultlinecolor'));

if ~holdflag, hold off; end
