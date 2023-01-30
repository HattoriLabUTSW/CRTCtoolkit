function crtc_batch_process_by_ubwonkonet(netfileloc,imgSz)
% Bonheur et al., 2022
%
% Function to batch process all 'data4*.mat' files by
% auto-segmentation using ubwonkonet. 
%
% Input is the network (use ResNet-50) and imgSz (224 for ResNet-50). It
% will save 1) padded image, 2) labeled image, and 3) calculated signals in
% the original data4*.mat file. If signals determined by manual ROI are
% present, these will be preserved. 
%
% This version scales input images for segmentation 
% Added a section to save segmented images as png.

load(netfileloc,'net');

% Pad image, scale intensity, convert to uint8, segment, calculate signals.
datamatfile = dir('data4*.mat');
segMode = "scaled";% "scaled" or "original"
segCateg = ["outside","cytosol","nucleus"];
padVal = 0;

%%%%% OUTPUT image size for PNG & Get window coordinate 
endImgSize = 100;
win = centerCropWindow2d([imgSz,imgSz],[endImgSize,endImgSize]);

nfile = length(datamatfile);
for ii = 1:nfile
    disp(['Processing file ',num2str(ii),'/',num2str(nfile),'...']);
    fn = datamatfile(ii).name;
    load(fn,'DATA');
    ncells = length(DATA.CELL);
    IMOUT = cell(1,ncells);
    for n = 1:ncells
        im = DATA.CELL(n).IMAGE;
        padIm = double(padImageCenter_f(im,imgSz,padVal));
        R = padIm(:,:,DATA.CHANNEL_RGB(1));
        G = padIm(:,:,DATA.CHANNEL_RGB(2));
        B = padIm(:,:,DATA.CHANNEL_RGB(3));
        Z_8 = uint8(zeros(size(R)));
        switch segMode
            case "scaled"
                R_8 = uint8((double(R)./max(R(:))) .* 255);
                B_8 = uint8((double(B)./max(B(:))) .* 255);
            case "original"
                if max(im(:)) > 255
                    R_8 = uint8(R./16);
                    B_8 = uint8(B./16);
                else
                    R_8 = uint8(R);
                    B_8 = uint8(B);
                end
        end
        segInput = cat(3,R_8,Z_8,B_8);
        C = semanticseg(segInput,net);
        L = zeros(imgSz);
        for k = 1:length(segCateg)-1
            L(C==segCateg(k+1)) = k;
        end
        L2 = uint8(cat(3,L==1,zeros(size(L)),L==2).*255);
        IMOUT{n} = [imcrop(segInput,win);imcrop(L2,win)];
        DATA.CELL(n).PADIMAGE = padIm;
        DATA.CELL(n).LABELIMAGE = L;
        DATA.CELL(n).ROISTR = segCateg;
        DATA.CELL(n).ubNET = netfileloc;
        DATA.CELL(n).ubSIGNAL.nuc.red = mean(R(L==2));
        DATA.CELL(n).ubSIGNAL.nuc.green = mean(G(L==2));
        DATA.CELL(n).ubSIGNAL.nuc.blue = mean(B(L==2));
        DATA.CELL(n).ubSIGNAL.cyto.red = mean(R(L==1));
        DATA.CELL(n).ubSIGNAL.cyto.green = mean(G(L==1));
        DATA.CELL(n).ubSIGNAL.cyto.blue = mean(B(L==1));
        DATA.CELL(n).ubSIGNAL.wholecell.red = mean(R(L>0));
        DATA.CELL(n).ubSIGNAL.wholecell.green = mean(G(L>0));
        DATA.CELL(n).ubSIGNAL.wholecell.blue = mean(B(L>0));
        % IF MANUAL SIGNAL NOT RECORDED, POPULATE THE FIELDS.
        if isempty(DATA.CELL(n).nucROI) && isempty(DATA.CELL(n).cellROI)
            DATA.CELL(n).SIGNAL.nuc.red = mean(R(L==2));
            DATA.CELL(n).SIGNAL.nuc.green = mean(G(L==2));
            DATA.CELL(n).SIGNAL.nuc.blue = mean(B(L==2));
            DATA.CELL(n).SIGNAL.cyto.red = mean(R(L==1));
            DATA.CELL(n).SIGNAL.cyto.green = mean(G(L==1));
            DATA.CELL(n).SIGNAL.cyto.blue = mean(B(L==1));
            DATA.CELL(n).SIGNAL.wholecell.red = mean(R(L>0));
            DATA.CELL(n).SIGNAL.wholecell.green = mean(G(L>0));
            DATA.CELL(n).SIGNAL.wholecell.blue = mean(B(L>0));
        end
    end
    IMOUTMAT = cell2mat(IMOUT);
    IMOUT2 = insertText(IMOUTMAT,[ncells*endImgSize/2,endImgSize],...
        fn,'anchorpoint','center',...
        'textcolor','w','fontsize',20,'boxopacity',0);
    save(fn,'DATA');
    imwrite(IMOUT2,strrep(fn,'.mat','_segIm.png'));
    disp(['File ',num2str(ii),'/',num2str(nfile),' done!']);
end