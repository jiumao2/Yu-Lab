function [ImageCellArray, headerInfo] = ReadJpegSEQ(fileName,frames)
% -------------------------------------------------------------------------
% Read compressed or uncompressed monochrome NorPix image sequence in MATLAB.
% This script can read all frames or a set reading window.
% Reading window for compressed sequences requires a separate .idx file
% named as the source file (eg. test.seq.idx).
% 
% INPUTS
%    fileName:       String containing the full path to the sequence
%    frames:         1x2 double array of beginning and end frame
% OUTPUTS
%    ImageCellArray: Cell array with images and timestamps of all allocated
%                    frames.
%    headerInfo:     Struct with header information (ImageWidth, 
%                    ImageHeight, ImageBitDepth, ImageBitDepthReal, 
%                    ImageSizeBytes, ImageFormat, AllocatedFrames, 
%                    Compression, HeaderVersion, HeaderSize, Description,
%                    TrueImageSize, FrameRate).
% EXAMPLES
%    Read frames 2 to 13:
%    ImageCellArray = ReadJpegSEQ('C:\test.seq',[2 13])
% 
%    Read all frames:
%    ImageCellArray = ReadJpegSEQ('C:\test.seq',[0 0])
%
%   Show header information:
%   [ImageCellArray, headerInfo] = ReadJpegSEQ('C:\test.seq',[0 0])
% 
% Last modified 06.11.2019 by Paul Siefert, PhD
% Goethe-University Frankfurt
% siefert@bio.uni-frankfurt.de
% 
% Based on the work of Brett Shoelson (Norpix2MATLAB_MarksMod.m)
% Thanks to NorPix support (Daniel Wang) for providing sequence information
% 
% This code was tested with Norpix SEQ
% 8-bit monochrome 75% lossy jpeg compression (24.07.2018)
% 8-bit monochrome uncompressed (03.06.2019)
% 
% Please report any bugs and improvement suggestions
% -------------------------------------------------------------------------

%% Open Sequence & Read Information
fid = fopen(fileName,'r','b'); % open the sequence
endianType = 'ieee-le'; % use little endian machine format ordering for reading bytes

fseek(fid,548,'bof');  % jump to position 548 from beginning
imageInfo = fread(fid,24,'uint32',0,endianType); % read 24 bytes with uint32 precision
headerInfo.ImageWidth = imageInfo(1);
headerInfo.ImageHeight = imageInfo(2);
headerInfo.ImageBitDepth = imageInfo(3);
headerInfo.ImageBitDepthReal = imageInfo(4);
headerInfo.ImageSizeBytes = imageInfo(5);
vals = [0,100,101,200:100:600,610,620,700,800,900];
fmts = {'Unknown','Monochrome','Raw Bayer','BGR','Planar','RGB',...
    'BGRx', 'YUV422', 'YUV422_20', 'YUV422_PPACKED', 'UVY422', 'UVY411', 'UVY444'};
headerInfo.ImageFormat = fmts{vals == imageInfo(6)};
fseek(fid,572,'bof');
headerInfo.AllocatedFrames = fread(fid,1,'ushort',endianType);
fseek(fid,620,'bof');
headerInfo.Compression = fread(fid,1,'uint8',endianType);
% Additional sequence information
fseek(fid,28, 'bof');
headerInfo.HeaderVersion = fread(fid,1,'long',endianType);
fseek(fid,32,'bof');
headerInfo.HeaderSize = fread(fid,4/4,'long',endianType);
fseek(fid,592, 'bof');
DescriptionFormat = fread(fid,1,'long',endianType)';
fseek(fid,36,'bof');
headerInfo.Description = fread(fid,512,'ushort',endianType)';
if DescriptionFormat == 0 %#ok Unicode
    headerInfo.Description = native2unicode(headerInfo.Description);
elseif DescriptionFormat == 1 %#ok ASCII
    headerInfo.Description = char(headerInfo.Description);
end
fseek(fid,580,'bof');
headerInfo.TrueImageSize = fread(fid,1,'ulong',endianType);
fseek(fid,584,'bof');
headerInfo.FrameRate = fread(fid,1,'double',endianType);

% abort if sequence is not monochome
assert(strcmp(headerInfo.ImageFormat,'Monochrome'),['Image format is not monochrome but ' headerInfo.ImageFormat '.'])

% analyze read window input
if size(frames,2)~=2
    error('False input arguments for frames. Please use 1x2 double array.')
% elseif frames(1) > headerInfo.AllocatedFrames || frames(2) > headerInfo.AllocatedFrames
%     error(['Some values of selcted frames (' num2str(frames) ') are above allocated frames of ' num2str(headerInfo.AllocatedFrames) '.'])
elseif frames(1) > frames(2)
    error(['Value of end frame (' num2str(frames(1)) ') is below first frame (' num2str(frames(2)) ').'])
end

% set read window & determine number of frames to read
if frames(1) <= 0, first = 1; else, first = frames(1); end
if frames(2) <= 0, last = headerInfo.AllocatedFrames; else, last = frames(2); end
readAmount = last+1 - first;

% use idx file for frame window in compressed seq
readWindow = 0;
if headerInfo.Compression == 1 && readAmount ~= headerInfo.AllocatedFrames
    fidIdx = fopen([fileName '.idx']);
    if fidIdx > 0
%         fprintf('Idx file found. Using idx information for SEQ reading.\n');
        readWindow = 1;
    else
        fprintf('No idx file found. Switching to full SEQ reading.\n');
    end
end

%% Start image reading
switch headerInfo.ImageBitDepthReal % set bit depth for reading
    case 8
        bitDepth = 'uint8';
    case {10,12,14,16}
        bitDepth = 'uint16'; % not tested
end
I = cell(readAmount,2); % create an empty cell to store images

if headerInfo.Compression == 1 % sequence is compressed
    % disable Warning: JPEG library error (8 bit), "Premature end of JPEG file".
    warning('off','MATLAB:imagesci:jpg:libraryMessage')
    if readWindow == 0 % user selected no read window
        
        readStart = 1024; % norpix compressed sequences have header size of 1024
        for i = 1:headerInfo.AllocatedFrames % begin loop
            
            % read image buffer size
            fseek(fid,readStart,'bof');
            imageBufferSize = fread(fid,1,'uint32',endianType);
            
            % read compressed image
            readStart = readStart+4;
            fseek(fid,readStart,'bof');
            SEQ = fread(fid,imageBufferSize,bitDepth,endianType);
            
            % read timestamp
            readStart = readStart+imageBufferSize-4;
            fseek(fid,readStart,'bof');
            time = readTimestamp(fid, endianType);
            I{i,2} = time;
            
            % write and read temp image
            tempName = 'tmpJpegSEQimg.jpg';
            tempFile = fopen(tempName,'w');
            fwrite(tempFile,SEQ);
            fclose(tempFile);
            I{i,1} = imread(tempName);
            
            
            % set read start to after timestamp
            readStart = readStart+8;
            
        end
        
    elseif readWindow == 1
        
        for i = 1:readAmount
            
            % read frame using idx buffer size information
            frame = first-1+i;
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
            
            % Use > two temp files to prevent fopen errors
            if mod(frame,2)
                tempName = '_tmp1.jpg';
            else
                tempName = '_tmp2.jpg';
            end
            tempFile = fopen(tempName,'w');
            if tempFile < 0
                tempName = '_tmp3.jpg';
                tempFile = fopen(tempName,'w');
            end
            fwrite(tempFile,JpegSEQ);
            fclose(tempFile);
            I{i,1} = imread(tempName);
            
            % read timestamp
            readStart = readStart+imageBufferSize-4;
            fseek(fid,readStart,'bof');
            time = readTimestamp(fid, endianType);
            I{i,2} = time;
        end
        fclose(fidIdx);
    end
    
elseif headerInfo.Compression == 0 % sequence is uncompressed
    
    numPixels = headerInfo.ImageSizeBytes;
    for i = 1:readAmount
        
        % set readStart of next frame
        readStart = ((first-1+i-1)*headerInfo.TrueImageSize)+8192;
        
        % read uncompressed image
        fseek(fid,readStart,'bof');
        UYVYcolVec = fread(fid, numPixels, bitDepth, endianType);
        UYVYimg = reshape(UYVYcolVec,headerInfo.ImageWidth,headerInfo.ImageHeight)';
        SEQ = uint8(UYVYimg);
        
        % read timestamp
        readStart = readStart + numPixels;
        fseek(fid,readStart,'bof');
        time = readTimestamp(fid, endianType);
        I{i,2} = time;
        I{i,1} = SEQ;
    end
end
fclose(fid);
ImageCellArray = I;
return

function time = readTimestamp(fid, endianType)
imageTimestamp = fread(fid,1,'int32',endianType);
subSec = fread(fid,2,'uint16',endianType);
subSec_str = cell(2,1);
for sS = 1:2
    subSec_str{sS} = num2str(subSec(sS));
    while length(subSec_str{sS})<3
        subSec_str{sS} = ['0' subSec_str{sS}];
    end
end
timestampDateNum = imageTimestamp/86400 + datenum(1970,1,1);
time = [datestr(timestampDateNum) ':' subSec_str{1},subSec_str{2}];
return
