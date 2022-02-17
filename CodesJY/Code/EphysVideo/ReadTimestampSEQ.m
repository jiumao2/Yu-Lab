function timestamp = ReadTimestampSEQ(fileName,frame)
% -------------------------------------------------------------------------
% Read compressed or uncompressed monochrome NorPix image sequence in MATLAB.
% Reading window for compressed sequences requires a separate .idx file
% named as the source file (eg. test.seq.idx).
% 
% INPUTS
%    fileName:       String containing the full path to the sequence
%    frames:         1x1 double of the frame index
% OUTPUTS
%    timeout:        the timestamp in second
% 
% Last modified 2021.4.30 by Yue Huang

% Open Sequence & Read Information
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

% read timestamp
readStart = readStart+imageBufferSize-4;
fseek(fid,readStart,'bof');

imageTimestamp = fread(fid,1,'int32',endianType);
subSec = fread(fid,2,'uint16',endianType);
timestamp = imageTimestamp*1000 + subSec(1) + subSec(2)/1000; % in millisecond

fclose(fidIdx);
fclose(fid);
end