function aomout=findAOMamps(aomin)

for i=1:size(aomin, 2)
    
    aomout(i)=round(100*(prctile(aomin(:, i), 90)-prctile(aomin(:, i), 10)))/100;
    
    
end;

