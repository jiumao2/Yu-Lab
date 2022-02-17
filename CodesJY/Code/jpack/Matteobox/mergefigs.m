function newfig = mergefigs(figlist,poslist)
% MERGEFIGS merges two or more figures
%
% fig = mergefigs(figlist,poslist)
% creates a new figure fig with the components of the figures listed 
% in figlist. 0oslist has a row [left bottom width height] for each fig.
%
% EXAMPLE:
% fig1 = figure; plot([ 1 2 3], [4 5 6], 'ro-');
% fig2 = figure; plot([ 1 2 3], [7 8 9], 'go-');
%
% % to put them side by side:
% newfig = mergefigs([fig1, fig2], [ 0 0 0.5 1 ; 0.5 0 0.5 1 ]);
% 
% % to put them on top of each other:
% newfig = mergefigs([fig1, fig2], [ 0 0 1 0.5 ; 0 0.5 1 0.5 ]);
% 
% 2001-03 Matteo Carandini
% part of the Matteobox toolbox

nfigs = length(figlist);

if any(size(poslist)~=[nfigs,4])
   error('Argument poslist should be nfigs X 4');
end

if any(poslist>1)
   error('Positions should be between 0 and 1');
end

for ifig = 1:nfigs
   if ~strcmp( get(figlist(ifig),'type'), 'figure')
      error(['Cannot find a figure number ' num2str(figlist(ifig)) ]);
   end
end

newfig = figure;

for ifig = 1:nfigs
   
   figpos = poslist(ifig,:);
   
   objs = get( figlist(ifig), 'children' );
   nobjs = length(objs);
   
   pp = zeros(nobjs,4); % matrix of positions
   for iobj = 1:nobjs
      thisobj = objs(iobj);
      set(thisobj,'units','normalized');
      pp(iobj,:) = get(thisobj,'position');
   end
   
   newobjs = copyobj( objs, newfig );
   for iobj = 1:nobjs
      thisobj = newobjs(iobj);
      oldpos = pp(iobj,:);
      newpos = oldpos; % just for allocation
      newpos([1 2]) = figpos([1 2])+oldpos([1 2]).*figpos([3 4]);
      newpos([3 4]) = oldpos([3 4]).*figpos([3 4]);
      set(thisobj,'position',newpos);
   end
   
end

return

%---------------- example

fig1 = figure;
subplot(4,1,1); plot([ 1 2 3], [4 5 6], 'ko-');
subplot(2,2,4); plot([ 1 2 3], [9 8 7], 'bs-');
supertitle('figure one');
fig2 = figure;
subplot(3,3,1); plot([ 1 2 3], [4 5 6], 'ro-');
subplot(1,3,2); plot([ 1 2 3], [4 5 6], 'ro-');
subplot(3,3,9); plot([ 1 2 3], [9 8 7], 'gs-');
supertitle('figure two');

figlist = [ fig1, fig2];

poslist = [ 0 0 0.5 1 ; 0.5 0 0.5 1 ];
