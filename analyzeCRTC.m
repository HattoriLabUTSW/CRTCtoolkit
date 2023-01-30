%% CRTC Analysis Routine
% - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
% Bonheur et al., 2022
%
% Runner for analyzing CRTC data.
%
%% OUTLINE OF ANALYSIS
% - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
%
% ANALYZE PER CZI FILE
% 1. Capture cell bodies from each CZI image by using:
%           crtc_get_cells_app (App)
% 2. Auto segment cells into nuc vs cyto using UbwonkoNet by:
%           crtc_batch_process_by_ubwonkonet (function)
% 3. Check and correct Ubwonko-based segmentation by:
%           crtc_correct_cells_app (App)
%
% --> These steps will generate a 'corr_data4_*.mat' file per CZI file.
%
% ORGANIZE DATA FOR ACROSS-CONDITION ANALYSIS
% Organize these 'corr_data4_*.mat' files (or 'data4*.mat' files if no
% manual correction on segmentation) into 'FLY01','FLY02',...,'FLYnn'
% folders such that each FLY folder contains all *data4*.mat files for the
% fly (e.g., if there are two .czi files per fly, then there will be two
% *data4*.mat files per folder). Sort these FLYnn folders into condition
% folders with names '1_condition1', '2_condition2',... etc. such that each
% condition folder contains FLYnn folders containing data for all flies in
% each condition.
%
% GROUP DATA PER CONDITION (OPTIONAL)
% 4. Collect data from all flies within a condition by:
%           crtc_per_condition_analysis_f (function)
%
% --> This step will produce per condition figure and save Excel with two
% sheets one containing data per cell and the other containing data per
% fly.
%
% ANALYZE ACROSS CONDITION
% 5. Collect data from all flies across condition by:
%           crtc_analyze_across_groups_f (function)
%
% --> This step first uses crtc_per_condition_analysis_f to
% reanalyze all the data in each condition folder, then collects all data
% from all conditions, does statistics, saves Excel and plots figures.
%
% 
%% NECESSARY TOOLBOX AND SUBFUNCTIONS
% - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
%
%   MATLAB Image Processing Toolbox
%
%   bio-format (folder of functions)
%       To read CZI files. Download bfmatlab.zip from OME website and add
%       the folder to MATLAB path. (https://www.openmicroscopy.org/bio-formats/)
%
%   readczi_f (function)
%       Load CZI files into MATLAB workspace.
%
%   padImageCenter_f (function)
%       To use UbwonkoNet (ResNet-50), we need to pad cell images using
%       this function.
%   
%   loadcolors (variables)
%       Load colors into MATLAB workspace.
%
%   crtcUbwonkoNet_resnet50.mat (network)
%       UbwonkoNet network.
%
%% 1: Capture cell bodies from each CZI image
% - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
%%
% This app loads each CZI image stack (specify channels - red channel will
% be used to identify best slice per cell) and lets you capture slice cell
% body images. Use spinner to find a slice in which a cell body cross
% section is most visible and draw rectangle around the cell. If cells
% overlap, try to make the rectangle as specific to one cell as possible.

clear;

crtc_get_cells_app;

%% 2: Auto segment cells into nuc vs cyto using UbwonkoNet
% - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
%%
% Start from parent folder of data4*.mat files. 
% If data4*.mat files contain manual ROI data, they will be preserved. If
% data4*.mat files do not contain manual ROI data, those fields will be
% populated with ubwonkonet determined signal values.
%
% 'netfileloc' is the path to crtcUbwonkoNet_resnet50.mat

clear;

netfileloc = '/Users/daisukehattori/Desktop/Bonheur et al Code/crtcUbwonkoNet_resnet50.mat';
imgSz = 224;
crtc_batch_process_by_ubwonkonet(netfileloc,imgSz);

%% 3: Check and correct Ubwonko-based segmentation
% - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
%%
% This launches app to go through all the cells to check and correct
% segmentation. It operates folder-wise and saves 'corr_data4_*.mat' files
% for all data4*.mat files in the folder regardless of whether segmentation
% corrected in each image.

clear;

crtc_correct_cells_app;

%% 4: Collect data from all flies within a condition (optional)
% - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
%%
% Start from a folder with 'FLY01','FLY02',...,'FLYnn'.

clear;
loadcolors; % THIS ALLOWS YOU TO USE DIFFERENT COLORS AS INPUT FOR FUNC.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% CHANGE THIS: 'expcondname' is the experimental condition string,
% indivcolor and meancolor are used as scatter plot colors, and dosave
% determines whether the resulting figures and data are saved as .fig,
% .png, and .xlsx.
expcondname = 'P1aCRTC_GH';% CHANGE THIS STRING TO DESCRIBE EXPERIMENT
indivcolor = LightGreen;% COLOR FOR INDIV CELL PLOT
meancolor = DarkGreen;% COLOR FOR MEAN PLOT
dosave = true;% SAVE DATA?
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

crtc_per_condition_analysis_f(expcondname,indivcolor,meancolor,dosave);

%% 5: Collect data from all flies within a condition (optional)
% - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
%%
% This section reanalyzes each condition using
% 'crtc_per_condition_analysis_f_220428', collects all data from all
% conditions, does statistics, saves Excel, and plots figures.

clear;
expname = 'P1a_SHvGH';% Excel will be saved as [expname,'_collectedData.xlsx']
colidx = [3,1];% Color index per group, 1:R,2:G,3:B,4:O,5:P,6:Br,7:Gray,8:Black
ylimrange = [-.1,.5];% YLim bound

crtc_analyze_across_groups_f(expname, colidx, ylimrange);

%% OPTIONAL SECTIONS
% - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
%% op1: MANUAL ANNOTATION
% - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
%%
% This version contains auto-ROI function using k-means segmentaion.
% Require 3-color images in which red is mCD8mCherry, green is CRTC-GFP,
% and blue is nucLacZ. To use this app;
%   1. Load a .czi image stack. You need to specify channels because red
%   channel is used to find cells.
%   2. Use the spinner to find a slice in which a cell body crosssection is
%   visible.
%   3. Draw rectangle around the soma.
%   4. Draw two polygon ROIs demarcating cellular boundary and nucleus
%   boundary. Auto-ROI available using k-means segmentation. Red channel
%   (mCD8mCherry) is shown as magenta and blue channel (nucLacZ) is shown
%   as green. You can also adjust brightness, and adjusting brightness
%   changes the performance of auto-ROI.
%   5. Once done with a cell, click next to go back and draw rectangle for
%   a next cell.
%   6. Rectangle-selected cells turn red.
%   7. Data will not be stored until "save" button is pushed

clear;
crtc_quantification_app;

%% op2: MAKE MIP IMAGES FOR ALL CZI FILES IN A FOLDER
% - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
%%
% Start from the folder that contains .czi files. Will make a folder per
% .czi and saves .png images of MIP per channel as well as merged MIP.

clear;
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% CHANGE THIS: indicate channel-to-color correspondence. For example, if
% channel 1 is red, 2 is green, 3 is blue then {'R','G','B'}
channel2color = {'R','G','B'};
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
make_mip_from_czi_f(channel2color)

