function I = ReadJpegSEQ(fileName,frame)
% -------------------------------------------------------------------------
% Read compressed or uncompressed monochrome NorPix image sequence in MATLAB.
% Reading window for compressed sequences requires a separate .idx file
% named as the source file (eg. test.seq.idx).
% 
% INPUTS
%    fileName:       String containing the full path to the sequence
%    frame:          1x1 double of the frame index
% OUTPUTS
%    I:              the image (matrix)
% 
% Last modified 2021.04.30 by Yue Huang

fid = fopen(fileName,'r','b'); % open the sequence
fidIdx = fopen([fileName '.idx']);
endianType = 'ieee-le'; % use little endian machine format ordering for reading bytes

% read frame using idx buffer size information
if frame == 1
    readStart = 1028;
    fseek(fidIdx,8,'bof');
    imageBufferSize = fread(fidIdx,1,'ulong',endianType);
else
    readStartIdx = frame*24;
    fseek(fidIdx,readStartIdx,'bof');
    readStart = fread(fidIdx,1,'uint64',endianType)+4;
    imageBufferSize = fread(fidIdx,1,'ulong',endianType);
end

fseek(fid,readStart,'bof');

JpegSEQ = fread(fid,imageBufferSize,'uint8',endianType);
I = uint8(py.cv2.imdecode(py.numpy.uint8(py.numpy.array(JpegSEQ)),uint8(0)));
fclose(fidIdx);
fclose(fid);
end