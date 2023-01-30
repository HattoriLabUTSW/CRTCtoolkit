function make_mip_from_czi_f(channel2color)
% Bonheur et al., 2022
%
% Works from a folder containing .czi files and saves MIP images for single
% channels as well as merge in folders with the same name as .czi files. If
% 3 colors, then R/G/B, if 2, then B/Y, and if 1, then G.
% 
% Input: channel2color - 1-by-3 cell array of string indicating channel to
% color matching. Usually {'R','G','B'}.
%       

% UPDATED TO AUTOMATICALLY DETERMINE 16-, 12-, or 8-bit.
% SAVE IMAGES AS 8-bit.
% UPDATE TO ALLOW DIFFERENT COLORS FOR 3COLOR IMAGES.

colororder = channel2color;
currfolder = pwd;
czifiles = dir('*.czi');

for n = 1:length(czifiles)
    currfile = czifiles(n).name;
    out = readczi_f(fullfile(pwd,currfile));
    nchannel = out.num_channel;
    images = out.images;
    MIPori = cell(nchannel,1);
    for c = 1:nchannel
        MIPori{c} = max(images{c},[],3);
    end
    
    % DETERMINE BIT-DEPTH 
    maxint = max(cellfun(@(x)max(x(:)),MIPori));
    if maxint > 2^12-1 % 16-bit
        MIP = cellfun(@(x)uint8(x./(2^8)),MIPori,'uni',false);
    elseif maxint > 2^8-1 % 12-bit
        MIP = cellfun(@(x)uint8(x./(2^4)),MIPori,'uni',false);
    else % 8-bit
        MIP = MIPori;
    end
    
    % Save images using imwrite
    savefolder = [currfile(1:end-4),'_MIPs'];
    mkdir(savefolder);
    cd(savefolder);
    siz = size(MIP{c});
    cls = class(MIP{c});
    mergeMIP = cast(zeros([siz,3]),cls);
    
    if nchannel == 3 %RGB
        addstr = {'R','G','B'};
        for c = 1:nchannel
            ci = find(strcmp(addstr,colororder{c}));
            indivMIP = cast(zeros([siz,3]),cls);
            indivMIP(:,:,ci) = MIP{c};
            mergeMIP(:,:,ci) = MIP{c};
            imwrite(indivMIP,[currfile(1:end-4),'_MIP_',addstr{ci},'.png']);
        end
        imwrite(mergeMIP,[currfile(1:end-4),'_MIP_merge.png']);
        
    elseif nchannel == 2 %Likely c1 = green, c2 = blue: make it yellow/blue
        indivMIP = cast(zeros([siz,3]),cls);
        indivMIP(:,:,2) = MIP{1};
        imwrite(indivMIP,[currfile(1:end-4),'_MIP_G.png']);
        indivMIP = cast(zeros([siz,3]),cls);
        indivMIP(:,:,3) = MIP{2};
        imwrite(indivMIP,[currfile(1:end-4),'_MIP_B.png']);
        mergeMIP(:,:,1) = MIP{1};
        mergeMIP(:,:,2) = MIP{1};
        mergeMIP(:,:,3) = MIP{2};
        imwrite(mergeMIP,[currfile(1:end-4),'_MIP_merge.png']);
        
    elseif nchannel == 1
        indivMIP = cast(zeros([siz,3]),cls);
        indivMIP(:,:,2) = MIP{1};
        imwrite(indivMIP,[currfile(1:end-4),'_MIP.png']);
    end
    disp([num2str(n),'/',num2str(length(czifiles))]);
    cd(currfolder);
end

%% Tile PNG files. Folderwise and save. 
currdir = pwd;
folders = dir;
folders = folders([folders.isdir]);
folders = {folders(3:end).name}';

for k = 1:length(folders)
    cd(folders{k});
    pngfiles = dir('*.png');
    nimages = length(pngfiles);
    images = cell(nimages,1);
    for n = 1:nimages
        images{n} = imread(pngfiles(n).name);
    end
    siz = size(images{1});
    newimage = cast(zeros(siz(1)*2,siz(2)*2,3),'like',images{1});
    
    indx = {[1:siz(1)],[1:siz(2)];[siz(1)+1:siz(1)*2],[1:siz(2)];...
        [1:siz(1)],[siz(2)+1:siz(2)*2];[siz(1)+1:siz(1)*2],[siz(2)+1:siz(2)*2]};
    for n = 1:nimages
        newimage(indx{n,1},indx{n,2},1:3) = images{n};
    end
    imwrite(newimage,[folders{k},'_tile.png']);
    disp(['finishing ',num2str(k),'/',num2str(length(folders))]);
    cd(currdir);
end
        
        
        
    
    
    
        
        
    
