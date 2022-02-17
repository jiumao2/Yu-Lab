function plotVth(Vth)

ntrials=length(Vth.trials);

figure;

axes('nextplot', 'add', 'xlim', [min(Vth.trials)-5 max(Vth.trials)+5])


for i=1:ntrials
    
    if ~isempty(Vth.threshold{i})
        plot(Vth.trials(i), Vth.threshold{i}, 'o', 'color', 'r');
    end;
end;

xlabel('trials')
ylabel('Spk threshold')