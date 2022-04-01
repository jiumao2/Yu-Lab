function AllocatedFrames = ReadFrameNumSEQ(filename)
    fid = fopen(filename,'r','b');
    endianType = 'ieee-le';
    fseek(fid,572,'bof');
    AllocatedFrames = fread(fid,1,'ulong',endianType)-1;
    fclose(fid);
end