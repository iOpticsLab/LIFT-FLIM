%% Figure 3 

%% load data
clc;clear;
close all;
load(['Figure3\fig3']);

%% Figure 2a-c

figure;
subplot 211; montage(inten_GT(:,:,1:4:end),'Displayrange', [0.0 1],'Size',[1,5]); colormap(gray);axis equal; % intensity groundtruth 
subplot 212; montage(inten_LIFT(:,:,1:4:end),'Displayrange', [0.0 1],'Size',[1,5]); colormap(gray);axis equal;% intensity LIFT-FLIM trconstruction

%
gap = [0.01 0.0]; % vertical horizontal
marg_w = [.0 .0];  %left right
marg_h = [.05 .05]; %lower upper

figure;
for i = 1:5
    subtightplot(1,5,i,gap,marg_h,marg_w);imagesc(Lifemap_LIFT(:,:,:,i),[1,5]);axis off equal; % lifemap LIFT-FLIM
end

%% Figure 2e histogram
edges = 1:0.03:4.8;

figure;hhh = histogram(hist_lifetime,edges);xlim([1 4.8]);box off
ax = gca;ax.FontSize = 15;ax.FontWeight="bold";

%% Figure 2d. Fluorescence decay at beads locations 
red4 = load(['Figure2_beads\depth0_red4']);
orange6 = load(['Figure2_beads\depth0_orange6']);
crimson10 = load(['Figure2_beads\depth0_crimson10']);

timex_red4 = red4.timex;timex_orange6 = orange6.timex;timex_crimson10 = crimson10.timex;
decaytemp_red4 = red4.decaytemp;decaytemp_orange6 = orange6.decaytemp;decaytemp_crimson10 = crimson10.decaytemp;
decaytemp_red4 = decaytemp_red4./max(decaytemp_red4);decaytemp_orange6 = decaytemp_orange6./max(decaytemp_orange6);
decaytemp_crimson10 = decaytemp_crimson10./max(decaytemp_crimson10);

optionsingle=fitoptions('exp1','StartPoint',[1,-1/3],'Lower',[0,-1/1],'Upper',[Inf, -1/4.8]); % set parameters in the fitting;  tune the parameter

[f_red4,gof_568]= fit(timex_red4',decaytemp_red4,'exp1',optionsingle);
[f_orange6,gof_488]= fit(timex_orange6',decaytemp_orange6,'exp1',optionsingle);
[f_crimson10,gof_488]= fit(timex_crimson10',decaytemp_crimson10,'exp1',optionsingle);
%
figure;plot(timex_red4',f_red4(timex_red4),'r','LineWidth',2);
hold on;plot(timex_red4',decaytemp_red4,'r^','MarkerSize',8);
hold on;plot(timex_orange6',f_orange6(timex_orange6),'g','LineWidth',2);
hold on;plot(timex_orange6',decaytemp_orange6,'go','MarkerSize',8);
hold on;plot(timex_crimson10',f_crimson10(timex_crimson10),'b','LineWidth',2);
hold on;plot(timex_crimson10',decaytemp_crimson10,'b*','MarkerSize',8);

xlim([0. 11]), ylim([0 1]); 
xlabel('Time(ns)','FontSize',25,'FontWeight','bold'), ylabel('Normalized intensity','FontSize',20,'FontWeight','bold'),
legend(['Red beads fitting \tau = ','4.0ns'],'Red beads Data',...
    ['Orange beads fitting \tau = ',num2str(round(-1/f_orange6.b,1)),'ns'],'Orange beads Data',...
    ['Crimson beads fitting \tau = ',num2str(round(-1/f_crimson10.b,1)),'ns'],'Crimson beads Data','Location','best','FontSize',20)
legend('boxoff') 
ax = gca;ax.FontSize = 20;ax.FontWeight="bold";box off;






