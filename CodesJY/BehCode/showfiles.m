function x=showfiles

 x=arrayfun(@(x)x.name, dir('*.txt'), 'UniformOutput', false)
 y=arrayfun(@(x)x.name, dir('*.mat'), 'UniformOutput', false)
 z=arrayfun(@(x)x.name, dir('*.avi'), 'UniformOutput', false)
 
 zz=arrayfun(@(x)x.name, dir('*.xlsx'), 'UniformOutput', false)