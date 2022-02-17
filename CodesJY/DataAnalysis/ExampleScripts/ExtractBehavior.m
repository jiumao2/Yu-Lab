filename = dir('*.nev');
openNEV(filename.name, 'report', 'read')  % open ‘datafile###.nev’, create “datafile###.mat”
EventOut = DIO_Events(NEV) % create 
