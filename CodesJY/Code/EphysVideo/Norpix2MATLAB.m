function [headerInfo, imgOut] = Norpix2MATLAB_MarksMod(fileName, showImg)
% Open n-bit Norpix image sequence in MATLAB
%
% ARGUMENTS:
%    INPUTS:
%    FILENAME: String name/path of image
%    SHOWIMG: Flag to display each image read (DEFAULT: False)
%    OUTPUTS:
%    HEADER: A structure containing Norpix version, header size (bytes),
%            description, image width, image height, image bit depth, image
%            bit depth (real), image size (bytes), image format, number of
%            allocated frames, origin, true image size, and frame rate.
%            (The user is referred to the manual for discussions of these
%            values.) Also returns the timestamp of each frame, in
%            Coordinated Universal Time (UTC).
%    IMGOUT: an ImageHeight x ImageWidth x AllocatedFrames image stack.
%
% SYNTAX:
% [header, imgOut] = Norpix2MATLAB(fileName, showImg)
%    Creates output variable HEADER, containing all header information and
%    image time-stamps, and IMGOUT, containing the image reconstructed from
%    file FILENAME.
% header = ...Norpix2MATLAB(...);
%    Returns only the header.
% [~,imgOut] = Norpix2MATLAB(...)
%    Returns only the image.
%
% EXAMPLE:
%     [header,img] = Norpix2MATLAB('640x480_14bit_10frames.seq',1)
%
% Written 04/08/08 by Brett Shoelson, PhD
% v.1.0
% brett.shoelson@mathworks.com
% Modifications:
% v2.0
% 12/01/10       Massive overhaul, to support 12-, 14-, and 16-bit images,
%                and to capture header information and timestamps. Also,
%                the syntax has changed: the user no longer inputs bit depth
%                or image size; those values are read from the header.
% v2.1
% 2015 Mar 3     Added support for YUV422 8-bit files

if nargin < 1
    error('fileName is a required input.');
elseif nargin < 2
    showImg = false;
end


% Open file for reading at the beginning
fid = fopen(fileName,'r','b');

% Both sequences are 640x480, 5 images each.
% The 12 bit sequence is little endian, aligned on 16 bit.
% The header of the sequence is 1024 bytes long.
% After that you have the first image that has
%
% 640 x 480 = 307200 bytes for the 8 bit sequence:
% or
% 640 x 480 x 2 = 614400 bytes for the 12 bit sequence:
%
% After each image there are timestampBytes bytes that contain timestamp information.
%
% This image size, together with the timestampBytes bytes for the timestamp,
% are then aligned on 512 bytes.
%
% So the beginning of the second image will be at
% 1024 + (307200 + timestampBytes + 506) for the 8 bit
% or
% 1024 + (614400 + timestampBytes + 506) for the 12 bit


%% HEADER INFORMATION
% A sequence file is made of a header section located in the first 1024
% bytes. The header contains information pertaining to the whole sequence:
% image size and format, frame rate, number of images etc.
% OBF = {Offset (bytes), Bytes, Format}

% Use the Little Endian machine format ordering for reading bytes
endianType = 'ieee-le';

% Read header

OFB = {28,1,'long'};
fseek(fid,OFB{1}, 'bof');
headerInfo.Version = fread(fid, OFB{2}, OFB{3}, endianType);
% headerInfo.Version

%
OFB = {32,4/4,'long'};
fseek(fid,OFB{1}, 'bof');
headerInfo.HeaderSize = fread(fid,OFB{2},OFB{3}, endianType);
if  headerInfo.Version >=5
    display('Version 5+ detected, overriding reported header size')
    headerInfo.HeaderSize = 8192
end
% headerInfo.HeaderSize

%
OFB = {592,1,'long'};
fseek(fid,OFB{1}, 'bof');
DescriptionFormat = fread(fid,OFB{2},OFB{3}, endianType)';
OFB = {36,512,'ushort'};
fseek(fid,OFB{1}, 'bof');
headerInfo.Description = fread(fid,OFB{2},OFB{3}, endianType)';
if DescriptionFormat == 0 %#ok Unicode
    headerInfo.Description = native2unicode(headerInfo.Description);
elseif DescriptionFormat == 1 %#ok ASCII
    headerInfo.Description = char(headerInfo.Description);
end
% headerInfo.Description

%
OFB = {548,24,'uint32'};
fseek(fid,OFB{1}, 'bof');
tmp = fread(fid,OFB{2},OFB{3}, 0, endianType);
headerInfo.ImageWidth = tmp(1);
headerInfo.ImageHeight = tmp(2);
headerInfo.ImageBitDepth = tmp(3);
headerInfo.ImageBitDepthReal = tmp(4);
headerInfo.ImageSizeBytes = tmp(5);
vals = [0,100,101,200:100:600,610,620,700,800,900];
fmts = {'Unknown','Monochrome','Raw Bayer','BGR','Planar','RGB',...
    'BGRx', 'YUV422', 'YUV422_20', 'YUV422_PPACKED', 'UVY422', 'UVY411', 'UVY444'};
headerInfo.ImageFormat = fmts{vals == tmp(6)};
%
OFB = {572,1,'ushort'};
fseek(fid,OFB{1}, 'bof');
headerInfo.AllocatedFrames = fread(fid,OFB{2},OFB{3}, endianType);
% headerInfo.AllocatedFrames

%
OFB = {576,1,'ushort'};
fseek(fid,OFB{1}, 'bof');
headerInfo.Origin = fread(fid,OFB{2},OFB{3}, endianType);
% headerInfo.Origin

%
OFB = {580,1,'ulong'};
fseek(fid,OFB{1}, 'bof');
headerInfo.TrueImageSize = fread(fid,OFB{2},OFB{3}, endianType);
% headerInfo.TrueImageSize

%
OFB = {584,1,'double'};
fseek(fid,OFB{1}, 'bof');
headerInfo.FrameRate = fread(fid,OFB{2},OFB{3}, endianType);
% headerInfo.FrameRate

%% Reading images
% Following the header, each images is stored and aligned on a 8192 bytes
% boundary (when no metadata is included)
imageOffset = 8192;

if nargout > 1
    bitstr = '';
    
    % Number of frames to do
    numFramesToProcess = 2;
    
    % To allocate a MATLAB array for the processed frames, use this:
    imgOut = uint8(zeros(headerInfo.ImageWidth,headerInfo.ImageHeight,numFramesToProcess));
    % For the whole array, use this:
    % imgOut = zeros(imSize(2),imSize(1),headerInfo.AllocatedFrames);
    
    switch headerInfo.ImageBitDepthReal
        case 8
            bitstr = 'uint8';
        case {10,12,14,16}
            bitstr = 'uint16';
    end
    if isempty(bitstr)
        error('Unsupported bit depth');
    end
    
    % Initialise variable for the number of frames read
    nread = 0;
    
    % Start the read loop
    for i = 1:numFramesToProcess
        % Go to the start of the current frame about to be read in. The first frame starts
        % after the header. Images are then sequential after the header. Reference for
        % file read position is the "beginning of file".
        fseek(fid, imageOffset + nread * headerInfo.TrueImageSize, 'bof');
        
        % Read, interpret and convert the data dependent on its format
        switch headerInfo.ImageFormat
            case 'UVY422'
                % Note: the StreamPix sequence records
                % ImageBitDepthReal: 16 (total bits per pixel, all channels)
                % ImageFormat: 'UVY422'
                % ImageBitDepth: 16 (wrong, since it is YUV, it should be 8)
                bitstr = 'uint8';
                % For 8-bit frames, each pixel from each channel is 1 byte
                % For UVY422 frames, the number of bytes to read is 2w*h
                numPixels = headerInfo.ImageWidth * headerInfo.ImageHeight * 2;
                % Read the current frame to a temporary column vector
                UYVYcolVec = fread(fid, numPixels, bitstr, endianType);
                
                % If the current frame is empty, we have reached the end of the frame sequence
                if isempty(UYVYcolVec)
                    break
                end
                
                % Reshape the matrix according to the sensor resolution 2w*h,
                % accounting for the UYVY format.
                UYVYimg = reshape(UYVYcolVec,headerInfo.ImageWidth*2,headerInfo.ImageHeight)';
                
                % Prepare a 3 channel image for Y, U, V channels
                YUV = zeros(headerInfo.ImageHeight,headerInfo.ImageWidth,3);
                
                % Copy in the Y channel
                YUV(:,:,1) = UYVYimg(:,2:2:end);
                % Copy in the U channel, and repeat for columns
                YUV(:,1:2:end,2) = UYVYimg(:,1:4:end);
                YUV(:,2:2:end,2) = UYVYimg(:,1:4:end);
                % Copy in the V channel, and repeat for columns
                YUV(:,1:2:end,3) = UYVYimg(:,3:4:end);
                YUV(:,2:2:end,3) = UYVYimg(:,3:4:end);
                
                % Convert to RGB
                RGB = ycbcr2rgb(uint8(YUV));
                
            case 'YUV422_PPACKED'
                % IK-1000 is 10-bit pixels, in YUV422, packed in 32-bits
                numPixels = headerInfo.ImageWidth * headerInfo.ImageHeight * 2;
                precision = 'ubit10=>uint16';
                skipBits = 2;
                
                % Read the current frame to a temporary column vector
                YUYVcolVec = fread(fid, numPixels, precision, skipBits, endianType);
                
                % Reshape the matrix according to the sensor resolution 2w*h,
                % accounting for the UYVY format.
                UYVYimg = reshape(YUYVcolVec,headerInfo.ImageWidth*2,headerInfo.ImageHeight)';
        end
        % Immediately after each frame is the 8 byte absolute timestamp at which the image
        % was recorded.
        % Read the next 32 bit (4 bytes) for the timestamp in seconds, formatted according
        % to the C standard time_t data structure (32-bit)
        timeSecsPOSIX = fread(fid, 1, 'int32', endianType);
        % Read the next 4 bytes as two 16-bit numbers (2 bytes each) to get the
        % millisecond and microsecond parts of the timestamp
        subSeconds = fread(fid,2,'uint16', endianType);
        % Convert the timestamp in seconds from POSIX time to typical datenum format
        timeDateNum = timeSecsPOSIX/86400 + datenum(1970,1,1);
        % Combine all numbers into a single timestamp
        headerInfo.timestamp{nread + 1} = [datestr(timeDateNum) ':' ...
            num2str(subSeconds(1)),num2str(subSeconds(2))];
        
        % If the user has requested that the images are displayed as the sequence is read
        if showImg
            % If the first frame has been read
            if nread == 0
                % Initialise the figure
                %figure('numbertitle','off','name',fileName,'color','k');
                figure,title(sprintf('frame %i',nread+1));
                % Display the image, giving the image display a handle
                himg = imshow(RGB);
            else % For subsequent images
                title(sprintf('frame %i',nread+1));
                % Display the image in the same axes in the current figure
                set(himg,'cdata',RGB);
            end
            
            % Show most recent graph window
            shg;
            drawnow;
            pause(1); % 1 second
        end
        
        % Update number of frames read
        nread = nread + 1;
    end
    
end

% Close the StreamPix *.seq file
fclose(fid);

