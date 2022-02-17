function vin=removelicknoise(tvm, vin, licks, intra)
if nargin<4
    intra=1;
end;

for i=1:length(licks)
    ilick=licks(i);
    ind_lick=find(tvm>=ilick-0.002 & tvm<=ilick+0.002);
    
    if intra && max(vin(ind_lick))<-10
        vin(ind_lick)=interp1([ind_lick(1) ind_lick(end)], vin([ind_lick(1) ind_lick(end)]), ind_lick);
    else
         vin(ind_lick)=interp1([ind_lick(1) ind_lick(end)], vin([ind_lick(1) ind_lick(end)]), ind_lick);
    end;
  
end;