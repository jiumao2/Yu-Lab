function Tracking = loadDLCcsv(filename)
    [data,txt,~] = xlsread(filename);
    bodyParts = cell(round((size(txt,2)-1)/3),1);
    coordinates_x = cell(length(bodyParts),1);
    coordinates_y = cell(length(bodyParts),1);
    coordinates_p = cell(length(bodyParts),1);
    for k = 1:length(bodyParts)
        bodyParts{k} = txt{2,3*k-1};
        coordinates_x{k} = data(:,3*k-1);
        coordinates_y{k} = data(:,3*k);
        coordinates_p{k} = data(:,3*k+1);
    end
    Tracking.BodyParts = bodyParts;
    Tracking.Coordinates_x = coordinates_x;
    Tracking.Coordinates_y = coordinates_y;
    Tracking.Coordinates_p = coordinates_p;
end