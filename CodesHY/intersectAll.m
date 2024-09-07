function out = intersectAll(cell_input)
    if length(cell_input) == 1
        out = cell_input{1};
        return 
    end
    
    out = cell_input{1};
    for k = 2:length(cell_input)
        out = intersect(out, cell_input{k});
    end
end