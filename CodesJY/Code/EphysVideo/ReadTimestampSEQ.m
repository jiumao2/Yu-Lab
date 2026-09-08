function timestamp = ReadTimestampSEQ(fileName,frame)
% -------------------------------------------------------------------------
% Read timestamps from a NorPix sequence index file in MATLAB.
% The .idx file must be named as the source file (eg. test.seq.idx).
%
% INPUTS
%    fileName:       String containing the full path to the sequence
%    frame:          1x1 double of the frame index, or -1 for all frames
% OUTPUTS
%    timestamp:      absolute timestamp in milliseconds (double)
%
% Last modified 2026.08.10 by Yue Huang

fidIdx = fopen([fileName '.idx']);
endianType = 'ieee-le'; % use little endian machine format ordering for reading bytes
assert(fidIdx >= 0, 'Cannot open index file: %s.idx', fileName);
cleanup = onCleanup(@() fclose(fidIdx));

fseek(fidIdx,0,'eof');
idxFileSize = ftell(fidIdx);
assert(idxFileSize > 0 && mod(idxFileSize,24) == 0, ...
    'Invalid index file size: %s.idx', fileName);
frameCount = idxFileSize/24;

assert(isnumeric(frame) && isscalar(frame) && isfinite(frame) && frame == fix(frame), ...
    'Frame must be an integer from 1 to %d, or -1 for all frames.', frameCount);

if frame == -1
    fseek(fidIdx,12,'bof');
    imageTimestamp = fread(fidIdx,frameCount,'int32=>double',20,endianType);
    fseek(fidIdx,16,'bof');
    milliseconds = fread(fidIdx,frameCount,'uint16=>double',22,endianType);
    fseek(fidIdx,18,'bof');
    microseconds = fread(fidIdx,frameCount,'uint16=>double',22,endianType);
    assert(numel(imageTimestamp) == frameCount && ...
        numel(milliseconds) == frameCount && numel(microseconds) == frameCount, ...
        'Incomplete timestamp data in index file: %s.idx', fileName);
    timestamp = (imageTimestamp*1000 + milliseconds + microseconds/1000)';
    return
end

assert(frame >= 1 && frame <= frameCount, ...
    'Frame must be an integer from 1 to %d, or -1 for all frames.', frameCount);

fseek(fidIdx,(frame-1)*24+12,'bof');
imageTimestamp = fread(fidIdx,1,'int32',endianType);
subSec = fread(fidIdx,2,'uint16',endianType);
assert(~isempty(imageTimestamp) && numel(subSec) == 2, ...
    'Incomplete timestamp data for frame %d.', frame);
timestamp = double(imageTimestamp)*1000 + double(subSec(1)) + double(subSec(2))/1000;

end
