function rname = r_name()
 
    this_folder          =      pwd;
    if ispc
        folder_split          =     split(this_folder, '\');
    elseif ismac
        folder_split          =     split(this_folder, '/');
    end;
    rat_name            =       folder_split{end-1};
    session_name    =       folder_split{end};

    rname               =      dir(['RTarray_*_', session_name, '.mat']);
    if ~isempty(rname)
        rname = rname.name;
    end;
 

