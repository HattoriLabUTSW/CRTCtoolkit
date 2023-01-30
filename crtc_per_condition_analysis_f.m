function crtc_per_condition_analysis_f(expname,indivcolor,meancolor,dosave)
% Bonheur et al., 2022
%
% CRTC group data per condition.
% Start from folder that contains 'FLY01', 'FLY02',... folders with each
% containing data4*.mat files
%
% UPDATE:
% If 'corr_data4*.mat' files exist in FLY folder, use them.
% UPDATE:
% Added lacZ signal so that one can sort cells based on expression levels.
% UPDATE:
% Added path to each data.mat file & cell ID per fly for the output Excel
% file.

MARKERSIZE = 60;
FONTSIZE = 20;

experiment = {};
flyID = [];
fileID = [];
filePath = [];
cellID = [];
NUC = [];
CYTO = [];
nucLacZ = [];

flyfolders = dir('FLY*');
nflies = length(flyfolders);
if nflies == 0
    errordlg('No FLY folders');
    return
end
currdir = pwd;
cellsperfly = cell(nflies,1);
for n = 1:nflies
    currCellID = 1;
    cd(flyfolders(n).name);
    % EACH FOLDER SHOULD ONLY CONTAIN EITHER corr_ or data4_ for each CZI
    % image.
    matfiles = dir('*data4_*.mat');
    currcellimages = {};
    for k = 1:length(matfiles)
        matpath = fullfile(matfiles(k).folder,matfiles(k).name);
        load(matpath,'DATA');
        currcellimages = [currcellimages,{DATA.CELL.IMAGE}];
        ncells = length(DATA.CELL);
        nuc = NaN(ncells,1);
        cyto = NaN(ncells,1);
        lacz = NaN(ncells,1);
        
        for p = 1:ncells
            %%%%%%%%%%% REDRAW ROI IF NAN %%%%%%%%%%%
            if isnan(DATA.CELL(p).SIGNAL.nuc.green) ||...
                    isnan(DATA.CELL(p).SIGNAL.cyto.green) ||...
                    isnan(DATA.CELL(p).SIGNAL.wholecell.green)
                cR = DATA.CELL(p).IMAGE(:,:,1);
                cG = DATA.CELL(p).IMAGE(:,:,2);
                cB = DATA.CELL(p).IMAGE(:,:,3);
                cRB = cat(3,cB,cR,cB).*16;
                hf = figure;
                ha = axes('parent',hf);
                imshow(cRB,'initialmag','fit','parent',ha);
                ANS = questdlg('Brightness okay?','Bright enough?','Yes','Too Dim','Yes');
                if strcmp(ANS,'Too Dim')
                    cRB = imadjust(cRB,[0,0.3]);
                    imshow(cRB,'initialmag','fit','parent',ha);
                end
                title('DRAW NUCLEUS BOUNDARY','parent',ha);
                NUCROI = drawpolygon('color','cyan','parent',ha);
                ANS = questdlg('Happy with the ROI?','Nucleus','Yes','Edit','Yes');
                if strcmp(ANS,'Edit')
                    hhelp = helpdlg('Edit and then close this dlg');
                    set(hhelp,'pos',[1937,914,197,70]);
                    uiwait(hhelp);
                end
                title('DRAW CELL BOUNDARY','parent',ha);
                CELLROI = drawpolygon('color','yellow','parent',ha);
                ANS = questdlg('Happy with the ROI?','Cell','Yes','Edit','Yes');
                if strcmp(ANS,'Edit')
                    hhelp = helpdlg('Edit and then close this dlg');
                    set(hhelp,'pos',[1937,914,197,70]);
                    uiwait(hhelp);
                end
                
                % Calculate mean intensities for all channels and update values in DATA
                mNUC = createMask(NUCROI);
                mCELL = createMask(CELLROI);
                mCYTO = mCELL~=mNUC;
                DATA.CELL(p).SIGNAL.nuc.red = mean(cR(mNUC));
                DATA.CELL(p).SIGNAL.nuc.green = mean(cG(mNUC));
                DATA.CELL(p).SIGNAL.nuc.blue = mean(cB(mNUC));
                DATA.CELL(p).SIGNAL.cyto.red = mean(cR(mCYTO));
                DATA.CELL(p).SIGNAL.cyto.green = mean(cG(mCYTO));
                DATA.CELL(p).SIGNAL.cyto.blue = mean(cB(mCYTO));
                DATA.CELL(p).SIGNAL.wholecell.red = mean(cR(mCELL));
                DATA.CELL(p).SIGNAL.wholecell.green = mean(cG(mCELL));
                DATA.CELL(p).SIGNAL.wholecell.blue = mean(cB(mCELL));
                DATA.CELL(p).nucROI = NUCROI.Position;
                DATA.CELL(p).cellROI = CELLROI.Position;
                % AND SAVE DATA
                save(matfiles(k).name,'DATA');
                delete(hf);
            end
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            
            nuc(p) = DATA.CELL(p).SIGNAL.nuc.green;
            cyto(p) = DATA.CELL(p).SIGNAL.cyto.green;
            lacz(p) = DATA.CELL(p).SIGNAL.nuc.blue;
            cellID = [cellID;currCellID];
            currCellID = currCellID + 1;
            
        end
        currExp = repmat({expname},ncells,1);
        
        experiment = [experiment;currExp];
        flyID = [flyID;repmat(n,[ncells,1])];
        fileID = [fileID;repmat(k,[ncells,1])];
        filePath = [filePath;repmat(string(matpath),[ncells,1])];
        NUC = [NUC;nuc];
        CYTO = [CYTO;cyto];
        nucLacZ = [nucLacZ;lacz];
    end
    
    sumimheight = max(cellfun(@(x)size(x,1),currcellimages));
    width = sum(cellfun(@(x)size(x,2),currcellimages));
    tiledim = uint16(zeros(sumimheight,width,3));
    curr_w = 1;
    for indivcells = 1:length(currcellimages)
        currim = currcellimages{indivcells};
        [h,w,~] = size(currim);
        hInd = floor((sumimheight-h)/2)+1:floor((sumimheight-h)/2)+h;
        wInd = curr_w:curr_w+w-1;
        tiledim(hInd,wInd,:) = currim;
        curr_w = curr_w+w;
    end
    cellsperfly{n} = tiledim;
    cd(currdir);
end
maxwidth = max(cellfun(@(x)size(x,2),cellsperfly));
sumheight = sum(cellfun(@(x)size(x,1),cellsperfly));
newim = uint16(zeros(sumheight,maxwidth,3));
curr_h = 1;
for n = 1:nflies
    currim = cellsperfly{n};
    [h,w,~] = size(currim);
    newim(curr_h:curr_h+h-1,1:w,:) = currim;
    curr_h = curr_h+h;
end
tiledImages = newim;

T = table(experiment,flyID,fileID,filePath,cellID,NUC,CYTO,nucLacZ);
T.NC = T.NUC./T.CYTO;
T.NLI = (T.NUC-T.CYTO)./(T.NUC+T.CYTO);

% Get per fly data
perfly_experiment = {};
perfly_flyID = [];
perfly_NC = [];
perfly_NLI = [];
for n = 1:nflies
    D = mean(T.NC(T.flyID==n));
    D2 = mean(T.NLI(T.flyID==n));
    perfly_experiment = [perfly_experiment;expname];
    perfly_flyID = [perfly_flyID;n];
    perfly_NC = [perfly_NC;D];
    perfly_NLI = [perfly_NLI;D2];
end

T2 = table(perfly_experiment,perfly_flyID,perfly_NC,perfly_NLI);

disp('Data collection done. Now Plotting...');
%% PLOTS
% 1: ALL CELLS SCATTER PER ANIMAL NLI
figure('color','w');
axes;hold on;
scatter(T.flyID,T.NLI,MARKERSIZE,...
    'markerfacecolor',indivcolor,'markeredgecolor',indivcolor,...
    'markerfacealpha',.5);
scatter(T2.perfly_flyID,T2.perfly_NLI,MARKERSIZE*2,...
    'markerfacecolor',meancolor,'markeredgecolor',meancolor);
set(gca,'xlim',[0,nflies+1],'xtick',1:nflies,...
    'linewidth',2,'tickdir','out','fontsize',FONTSIZE);
if contains(expname,'_')
    titlestr = strrep(expname,'_','-');
else
    titlestr = expname;
end
title(titlestr);
xlabel('Fly');
ylabel('NLI');
hold off;


%% SHOW IMAGES
figure('color','w');
ha = subplot(211);
imshow(tiledImages.*16);
title(titlestr,'parent',ha);
hb = subplot(212);
imshow(imcomplement(tiledImages(:,:,2).*16),'parent',hb);
title([titlestr,':CRTC'],'parent',hb);
%%
if dosave
    imwrite(tiledImages.*16,[expname,'_cellImages','.png']);
end

%% 
if dosave
    writetable(T,[expname,'_DATA.xlsx'],'Sheet','ALL CELLS');
    writetable(T2,[expname,'_DATA.xlsx'],'Sheet','PER FLY');
    hgsave(get(0,'children'),[expname,'_FIGURE.fig']);
end

disp('All done!');