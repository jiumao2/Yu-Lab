function shape_out = shape_it(shape_in)

% make sure the input has the standard shape: n x 1

if size(shape_in, 1)==1 
    shape_out = shape_in';
else
    shape_out = shape_in;
end