% ReconMain.m - MR image reconstruction from Pfile
% Marquette University
% EECE 4510/5510
%
% Fred J. Frigo
% Oct 17, 2017
% Oct 25, 2017 - modified for homodyne


% Enter name of Pfile
pfile = 'P20992.7';
slice_no = 6;
num_channels = -1;

%1: Read Pfile containing the raw data for each channel
% if num_channels == -1, it will read all the receiver channels.
% if num_channels == 1, it will prompt you for the specific channel at
%       the matlab console.
[raw_data, alternate] = getChannelData(pfile, slice_no, num_channels);

%2: Perform Fermi apodization and chopping
xdim = size(raw_data, 1);
ffilter = fermi(xdim, 0.45*xdim, 0.1*xdim);
%ffilter = fermi(xdim, 0.05*xdim, 0.1*xdim);  % Extra Apod
%mesh(ffilter);  % this plots the Fermi filter
filt_data = filterChannelData(raw_data, ffilter, alternate);

% display the k-space magnitude 
displayMagnitude(filt_data, 'K-space log-magnitude', 1);

%3: Transform to image domain
im_data = pifftChannelData(filt_data);

%4: Display the image magnitude for each channel
displayMagnitude(im_data, 'Image magnitude', 0);

%5: obtain channel weights used in sum of squares combination
weights = read_weights(pfile);

%6: calculate sum_square image
sos_image = sumOfSquares(im_data, weights);

%7: Read DICOM image file to obtain DICOM header info 
dfile = 'e31s3i11';
   
% Get DICOM info from input image.
info1 = dicominfo(dfile);
exam = info1.StudyID;
series = info1.SeriesNumber;
image_number1 = info1.InstanceNumber;
 
% Create a new DICOM image... starting with header from image1
info = info1;
  
info.WindowWidth  = max(max(sos_image));  %default window width for new image
info.WindowCenter = info.WindowWidth/2;  %defautl window level for new image
  
% Multiply original series by 100 and add 20 for new series number
info.StudyID = exam;
info.SeriesNumber= series*100 + 80;
info.InstanceNumber = image_number1;
info.SeriesInstanceUID = dicomuid;  %generate a new DICOM UID for new series

% Create name of NEW DICOM file to create
new_dfile = strcat('e',info.StudyID,'s',int2str(info.SeriesNumber),'i', int2str(info.InstanceNumber), '.new');
  
% Create the new DICOM image  
result = dicomwrite(sos_image,new_dfile,info,'CreateMode','copy');

msg=sprintf('New dicom file created (Homodyne) = %s', new_dfile);
msg

