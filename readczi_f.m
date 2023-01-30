function out = readczi_f(path2file)
% Bonheur et al., 2022
%
% Read .czi files using bio-formats. 10/22/2018 Daisuke
% Change 180630 version so that the input is file path.
% Output is a struct with fields, filepath, images, num of zslices, and num
% of channels.
%% Use Bio-format for CZI files 
% Downloaded bfmatlab.zip from OME website and added the folder to MATLAB
% path

data = bfopen(path2file);

%% Parse data
% data{1} contains all images and associated parameters. 
im = data{1}(:,1);
param = data{1}(:,2);

% Determine 1) how many slices and 2) how many channels by identifying
% where semicolons are (which are the separator (ASSUMED)).
param1 = param{1};% First slice, first channel
ind_semicolon = strfind(param1,';');
ind_z = strfind(param1,'Z=1/');
ind_c = strfind(param1,'C=1/');
ind_plane = strfind(param1,'plane 1/');
% Z info is before the last semicolon, and C info is at the end.
num_z = str2double(param1(ind_z+4:ind_semicolon(end)-1));
num_c = str2double(param1(ind_c+4:length(param1)));
num_tot = str2double(param1(ind_plane+8:ind_semicolon(end-1)-1));
if ~isequal(num_z*num_c,num_tot)
    errordlg('Parsing slices and channels failed. Look at param.');
    return
end

% Now make output image as cell array of the size of channel so that out{c}
% contains all slices of the channel c.
images = cell(1,num_c);
for c = 1:num_c
    ind = c:num_c:num_tot;
    images{c} = cat(3,im{ind});
end


%% All output
out.filepath = path2file;
out.images = images;
out.num_zslice = num_z;
out.num_channel = num_c;



    