%% Figure 4

%% 
clc;clear;
close all;

load(['Figure4\fig4']);

%% Figure 3a Reference image at depth = 0 

figure;imagesc(inten_ref,[0,1]);axis off equal;colormap gray;c = colorbar; 
c.Label.String='Normalized Intensity(a.u.)';  c.FontSize=16; c.FontWeight='bold';c.Location = "westoutside";c.Direction = "normal";

%% Figure 3b Refocused lifemaps at representative depths
% load z = -8 -4 0 4 8um lifemap
maxlife=3.2;minlife=2.2;
for i = 1:4:17
figure;
hm = axes;
imagesc(hm,lifemap_LIFT(:,:,:,i),'alphadata',1,[minlife,maxlife]);
axis off equal
u1=colormap('jet');colormap(hm,u1);
cbm=colorbar(hm); cbm.Label.String='Lifetime(ns)';  cbm.FontSize=16; cbm.FontWeight='bold';
end

%% Figure 3c histogram at z = 0um
lifevalue = lifevalue.*intenmask;
temp = lifevalue(lifevalue>0.5 & lifevalue<3.5);
edges = 0.5:0.02:3.36;
figure;hhh = histogram(temp,edges);xlim([2.2 3.2]);box off
ax = gca;ax.FontSize = 15;ax.FontWeight="bold";

%% Figure 3d. Fluorescence decay at two fluorophore locations 
decaytemp_568 = decaytemp_568./max(decaytemp_568);decaytemp_488 = decaytemp_488./max(decaytemp_488);
optionsingle=fitoptions('exp1','StartPoint',[1,-1/2],'Lower',[0,-1/0.5],'Upper',[Inf, -1/3.5]); % set parameters in the fitting;  tune the parameter 
[f_568,gof_568]= fit(timex_568',decaytemp_568,'exp1',optionsingle);
[f_488,gof_488]= fit(timex_488',decaytemp_488,'exp1',optionsingle);
figure;plot(timex_568',f_568(timex_568),'r','LineWidth',2);
hold on;plot(timex_568',decaytemp_568,'r^','MarkerSize',8);
hold on;plot(timex_488',f_488(timex_488),'g','LineWidth',2);
hold on;plot(timex_488',decaytemp_488,'go','MarkerSize',8);
xlim([0. 11]), ylim([0 1]); 
xlabel('Time(ns)','FontSize',25,'FontWeight','bold'), ylabel('Normalized intensity(a.u.)','FontSize',20,'FontWeight','bold'),
legend(['Phalloidin fitting \tau = ',num2str(round(-1/f_568.b,1)),'ns'],'Phalloidin Data',...
    ['Wheat germ agglutinin fitting \tau = ',num2str(round(-1/f_488.b,1)),'ns'],'Wheat germ agglutinin Data','Location','best','FontSize',20)
legend('boxoff') 
ax = gca;ax.FontSize = 20;ax.FontWeight="bold";box off;


%% Figure 3e-f Phasor plot at depth = 0; Figure 3f unmixed fluorophore image at depth = 0
[G_unmix0,S_unmix0,U] = blind_unmixing(double(Gl_all'),double(Sl_all'),2,Ch_vect,0);

figure
plot(Gl_all(1:1:end),Sl_all(1:1:end),'.','MarkerSize',4,'MarkerEdgeColor','m')
plot_rainbow(G_unmix0,S_unmix0,'o'); hold on;
legend('Data','Wheat germ agglutinin','Phalloidin','Semicircle','Location','best','FontSize',12)
legend('boxoff') 
ax = gca;ax.FontSize = 15;ax.FontWeight="bold";box off;
% blind unmixing
phasorlifeblind_lsf = zeros(270,270,2);
fs = Phasor_Unmixing2comp_simplified(Gl_all1',Sl_all1',G_unmix0([1 2])',S_unmix0([1 2])');  % row is the different G values
fs1 = fs(1,:);
fs2 = fs(2,:);
phasorlifeblind_lsf(:,:,1) = reshape(fs1,[270,270]);
phasorlifeblind_lsf(:,:,2) = reshape(fs2,[270,270]);
loc1=isnan(phasorlifeblind_lsf);
phasorlifeblind_lsf(loc1)=0;
% Rendering lifemap 
inten = im_f.*intenmask;inten=norm1(inten); 
rgt = zeros(size(intenmask));
rlife1=phasorlifeblind_lsf(:,:,1).*intenmask;  % 555--(actin) The SMA (actin) will be dotted structure
rlife2=phasorlifeblind_lsf(:,:,2).*intenmask;  % 546--(collagen) fibrosus structures deposited on the surface of the beads.
LIFEMAP=ind2rgb(floor(rgt),gray); % final map rgb image
[a,b,~]=size(LIFEMAP);
for k=1:a
    for j=1:b  
         LIFEMAP(k,j,:)=inten(k,j)*[rlife2(k,j) rlife1(k,j) 0]*gtlifemask(k,j)*2.5;% green;% green
    end
end 
figure;imagesc(LIFEMAP);axis off equal

%% output phasorplot heatmap
Gl_cluster = Gl_all;Sl_cluster = Sl_all;
Gl_cluster(Gl_cluster<0) = 0;Sl_cluster(Sl_cluster<0) = 0;
fov2 = [0,max(1,max(Gl_cluster));0,max(0.5,max(Sl_cluster))]; 
figsize = [256,128]*6;
[I,tk1,tk2,remap] = hist2D(Gl_cluster,Sl_cluster,figsize,fov2);% output phasorplot heatmap

I(I<2) = 0;

figure;imagesc(I,[0 max(I(:))]);%colormap(superjet(255,'wSbZctglyGorrmp'));hold on;
whiteturbo = [1,1,1;colormap('turbo')];
colormap(whiteturbo);
c = colorbar;c.Label.String='Counts';  c.FontSize=16;c.FontWeight='bold';
fs = Phasor_Unmixing2comp_simplified(Gl_all',Sl_all',G_unmix0([1 2])',S_unmix0([1 2])');  % row is the different G values

%%
colors=superjet(2,'gr');

K=2;
X = [Sl_cluster,Gl_cluster];

probs = fs';

[PP0,tk1,tk2,remap] = hist2D(X(:,2),X(:,1),figsize,fov2);% output phasorplot heatmap
PP0(PP0<2) = 0;
indsin=find(PP0>max(max(PP0))*.0);
indsref=sub2ind(size(PP0),remap(:,1),remap(:,2));
Np=length(indsin);
P2=ones(size(PP0,1),size(PP0,2),3);
for jj=1:Np
    percentatge(jj,Np);
    aux=find(indsin(jj)==indsref);

    prob=mean(probs(aux,:),1);
    %                 if((numel(unique(remapping(aux,1)))>1)||(numel(unique(remapping(aux,1)))>1))
    %                     disp(jj)
    %                 end
    pos=remap(aux(1),1:2);
    col=[0 0 0];
    for kk=1:K
        col=col+colors(kk,:)*prob(1,kk);
    end
    col(col>1)=1;
    P2(pos(1),pos(2),1:3)=col;
end

PP0=P2;

% change the bkg color to black
for i = 1:size(PP0,1)
    for j = 1:size(PP0,2)
        if PP0(i,j,:) == [1 1 1]
            PP0(i,j,:) = [0 0 0];
        end
    end
end

figure;imagesc(PP0);

%% Fgure 3g. 3D view of unmixed fluorophore distribution 

% volshow vosulization
fig = uifigure(Name="3D unmixed");
g = uigridlayout(fig,[1 1],Padding=[0 0 0 0]);
config = viewer3d(g);
config.BackgroundColor = [0,0,0];
config.BackgroundGradient = 0;
config.Lighting = 0;
config.CameraZoom = 1.2520;
config.ScaleBar = 0;
config.ScaleBarUnits = 'µm';
config.RenderingQuality = 'high';
config.Box = "on";
config.CameraPosition = [70.9132  165.7993  -93.5183];
config.CameraUpVector = [ 0.0249   -0.4012   -0.9157];

h = volshow(refocus_volume_resize_rescale,Parent=config);
