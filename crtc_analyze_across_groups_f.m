function crtc_analyze_across_groups_f(expname, colidx, ylimrange, dosave)
% Bonheur et al., 2022
%
% This function collects CRTC data across conditions, does statistics,
% saves Excel, and plot figures. 
% Input arguments:
%       'expname', string, used for Excel name as well as Fig name
%       'colidx', [1-by-n] array, where n is num groups. Index of
%               colors from 'loadcolors'
%       'ylimrange', [1-by-2] array.
% The function requires 'crtc_per_condition_analysis_f' and its
% associated functions.
% UPDATE:
% Use 'crtc_per_condition_analysis_f' so that 'corr_data4*.mat'
% files can be used for analysis.

%% 1: Reanalyze per group and save excel.
currdir = pwd;
folders = dir(currdir);
folders = folders([folders.isdir]);
folders = folders(3:end);% First 2 folders ./ and ../
foldername = {folders.name}';
ncond = length(foldername);
for k = 1:ncond
    currname = foldername{k};
    cd(currname);
    expcondname = [expname,'_',currname];
    crtc_per_condition_analysis_f(expcondname,'k','r',true);
    cd(currdir);
    delete(get(0,'children'));
end

%% 2: Collect data across groups and save combined Excel.
collected_data_cell = table;
collected_data_fly = table;
for k = 1:ncond
    currname = foldername{k};
    cd(currname);
    xls = dir([expname,'*.xlsx']);
    data_cell = readtable(xls(1).name,'Sheet','ALL CELLS');
    data_fly = readtable(xls(1).name,'Sheet','PER FLY');
    ncell = size(data_cell,1);
    nfly = size(data_fly,1);
    newdata_cell = [array2table(repmat(k,[ncell,1]),'VariableNames',"condID"),...
        data_cell];
    newdata_fly = [array2table(repmat(k,[nfly,1]),'VariableNames',"condID"),...
        data_fly];
    collected_data_cell = [collected_data_cell;newdata_cell];
    collected_data_fly = [collected_data_fly;newdata_fly];
    
    cd(currdir);
end

if dosave
    saveexcelname = [expname,'_collectedData.xlsx'];
    writetable(collected_data_cell,saveexcelname,'Sheet','ALL CELLS');
    writetable(collected_data_fly,saveexcelname,'Sheet','PER FLY');
end

if contains(expname,'_')
    titleheader = strrep(expname,'_','-');
else
    titleheader = expname;
end
figure;
subplot(121);
boxplot(collected_data_cell.NLI,collected_data_cell.condID);
title([titleheader,': per cell']);ylabel('NLI');set(gca,'xticklabel',foldername);
subplot(122);
boxplot(collected_data_fly.perfly_NLI,collected_data_fly.condID);
title([titleheader,': per fly']);ylabel('NLI');set(gca,'xticklabel',foldername);

%% 3: Statistics and save Excel
% KW for all + ranksum for all pairwise
[p,tbl,stat] = kruskalwallis(collected_data_fly.perfly_NLI,collected_data_fly.condID)
mcr = multcompare(stat)
combi = nchoosek(1:ncond,2);
ncombi = size(combi,1);
rspval = NaN(ncombi,1);
for k = 1:ncombi
    c1 = combi(k,1);
    c2 = combi(k,2);
    rspval(k) = ranksum(collected_data_fly.perfly_NLI(collected_data_fly.condID==c1),...
        collected_data_fly.perfly_NLI(collected_data_fly.condID==c2));
end

if dosave
    writetable(table([tbl;num2cell(mcr)]),saveexcelname,'Sheet','KW');
    writetable(table([combi,rspval]),saveexcelname,'Sheet','Ranksum');
end
    

%% 4: Plot scatter/box for all groups and save Fig
loadcolors;
colors(8).Dark = [0,0,0];%% To be able to concatenate

ytext = ylimrange(1)+0.025;

T = readtable(saveexcelname,'Sheet','PER FLY');

condID = T.condID;
NLI = T.perfly_NLI;


colmat = [];
ncond = max(condID);
figure('color','w');
axes;hold on;
for n = 1:ncond
    currnli = NLI(condID==n);
    scatter(ones(size(currnli)).*n,currnli,50,...
        'markeredgecolor',colors(colidx(n)).Light,...
        'markerfacecolor',colors(colidx(n)).Light,...
        'markerfacealpha',1);
    colmat = [colmat;colors(colidx(n)).Dark];
    text(n,ytext,['(',num2str(length(currnli)),')'],...
        'horizontalalign','center','fontsize',15);
end
h = boxplot(NLI,condID,'color',colmat);
ho = h(arrayfun(@(x)strcmp(get(x,'tag'),'Outliers'),h));
set(h,'linewidth',2);
set(ho,'visible','off');
box off

set(gca,'ylim',ylimrange,'xlim',[0.5,ncond+.5],'linewidth',2,'tickdir','out',...
    'ticklength',[.025,.025],'fontsize',15);
ylabel('NLI');
xlabel('Conditions');


% Save fig
if dosave
    savefilename = [expname,'.fig'];
    hgsave(get(0,'children'),savefilename);
end
