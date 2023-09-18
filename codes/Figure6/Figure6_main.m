%% Figure 6 

%% 
clc;clear;
close all;

load(['Figure6\fig6']);

%% Fig 6a
load('purephasorwavetimeall_5timepoints.mat');

figure;plot(waveall,wave532,'*-b','LineWidth',2,'MarkerSize',8);hold on;
plot(waveall,wave546,'*-c','LineWidth',2,'MarkerSize',8);hold on;plot(waveall,wave555,'*-g','LineWidth',2,'MarkerSize',8);hold on;
plot(waveall,wave568,'*-r','LineWidth',2,'MarkerSize',8);
legend('AF532','AF546','AF555','AF568','Location','best','FontSize',20)
% figure;plot(wave532_re,'*-');hold on;
% plot(inten546,'*-');hold on;plot(inten555,'*-');hold on;plot(wave565_re,'*-');
xlabel('Wavelength(nm)','FontSize',25,'FontWeight','bold'), ylabel('Normalized intensity(a.u.)','FontSize',20,'FontWeight','bold'),
legend('boxoff') 
ax = gca;ax.FontSize = 20;ax.FontWeight="bold";box off;

figure;plot(timex,inten532,'*-b','LineWidth',2,'MarkerSize',8);hold on;
plot(timex,inten546,'*-c','LineWidth',2,'MarkerSize',8);hold on;plot(timex,inten555,'*-g','LineWidth',2,'MarkerSize',8);hold on;
plot(timex,inten568,'*-r','LineWidth',2,'MarkerSize',8);
legend('AF532','AF546','AF555','AF568','Location','best','FontSize',20)
% figure;plot(wave532_re,'*-');hold on;
% plot(inten546,'*-');hold on;plot(inten555,'*-');hold on;plot(wave565_re,'*-');
xlabel('Time(ns)','FontSize',25,'FontWeight','bold'), ylabel('Normalized intensity(a.u.)','FontSize',20,'FontWeight','bold'),
legend('boxoff') 
ax = gca;ax.FontSize = 20;ax.FontWeight="bold";box off;

%% Fig 6b-d
figure;imagesc(img_ref);colormap gray;axis off equal

load(['LIFEMAP_depth6']);
inten_depthall = squeeze(inten_depthall);
intenmask_all = zeros(squeeze(size(inten_depthall)));
clear BW
for i = 1:size(intenmask_all,3)
    T = adaptthresh(norm1(inten_depthall(:,:,i)), 0.5);
    BW(:,:,i) = imbinarize(inten_depthall(:,:,i),T).*fovmask_l;
end
intenmask_all(inten_depthall>0.1) = 1;

%
Xrange = 390:1606;Yrange = 441:1657;
gap = [0.003 .00]; % vertical horizontal
marg_w = [.04 .04];  %left right
marg_h = [.0 .00]; %lower upper
figure
for count = 1:size(intenmask_all,3)
    LIFEMAP_M = squeeze(LIFEMAP_depthall(:,:,:,count).*BW(:,:,count).*intenmask_all(:,:,count));
    hm = axes;
    imagesc(hm,LIFEMAP_M.*1,'alphadata',1,[minlife,maxlife]);
    axis off equal
    u1=colormap('hot');colormap(hm,u1);
        cbm=colorbar(hm); cbm.Label.String='Lifetime(ns)';  cbm.FontSize=16;cbm.FontWeight='bold';
    subtightplot(1,size(intenmask_all,3),count,gap,marg_h,marg_w);
    imagesc(LIFEMAP_M(Yrange,Xrange,:).*1,'alphadata',1,[minlife,maxlife]);colormap('hot');
    axis off equal
end

load(['WAVEMAP_depth6']);
waverange = 7;
Xrange = 390:1606;Yrange = 441:1657;
gap = [0.003 .00]; % vertical horizontal
marg_w = [.04 .04];  %left right
marg_h = [.0 .00]; %lower upper
figure
for count = 1:size(intenmask_all,3)
    WAVEMAP_M = squeeze(WAVEMAP_depthall(:,:,:,count).*BW(:,:,count).*intenmask_all(:,:,count));
    subtightplot(1,size(intenmask_all,3),count,gap,marg_h,marg_w);
    imagesc(WAVEMAP_M(Yrange,Xrange,:).*1,'alphadata',1,[waveall(1),waveall(waverange)]);colormap('cool');
    axis off equal
end

    figure;
    hm = axes;
    imagesc(hm,WAVEMAP_M.*1,'alphadata',1,[waveall(1),waveall(waverange)]);
    axis off equal
    u1=colormap('cool');colormap(hm,u1);
        cbm=colorbar(hm); cbm.Label.String='Wavelength(nm)';  cbm.FontSize=16;cbm.FontWeight='bold';

%% figure 6e
colors=superjet(2,'gr');
colorcontrast = [1,1];
clear mu sigmas
K=2;
X = [Sl_cluster,Gl_cluster];

[PP0,tk1,tk2,remap] = hist2D(X(:,2),X(:,1),figsize,fov2);% output phasorplot heatmap

photonthresh = 0;
PP0(PP0<photonthresh) = 0;
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
        col=col+colors(kk,:)*prob(1,kk)*colorcontrast(kk);
    end
    col(col>1)=1;
    P2(pos(1),pos(2),1:3)=col;
end

clusterchosen = 1;
% clusteridx = IDX0;
indnow = find(clusteridx == clusterchosen);
length(indnow)
for jj=1:length(indnow)
    jj
    prob=probs(indnow(jj),:);
    col=[0 0 0];
    for kk=1:K
           col=col+colors(1,:)*10000;
    end
    P2(remap(indnow(jj),1),remap(indnow(jj),2),1:3)=col;
end

PP0=P2.*maskI.*maskedge;

% change the bkg color to black
for i = 1:size(PP0,1)
    for j = 1:size(PP0,2)
        if PP0(i,j,:) == [1 1 1]
            PP0(i,j,:) = [0 0 0];
        end
    end
end

figure;imagesc(PP0);


%% figure 6f
load(['Figure6\fig6_a']);

K=3;
X = [Ss_cluster,Gs_cluster];

clusterchosen = 3;
indnow = find(clusteridx == clusterchosen);
length(indnow)

[PP0,tk1,tk2,remap] = hist2D(X(:,2),X(:,1),figsize,fov2);% output phasorplot heatmap
% remap: [s,g,index];
PP0(PP0<photonthresh) = 0;
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

for jj=1:length(indnow)
    jj
    prob=probs(indnow(jj),:);
    col=[0 0 0];
    for kk=1:K
           col=col+colors(3,:)*10000;
    end
    P2(remap(indnow(jj),1),remap(indnow(jj),2),1:3)=col;
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

%% figure 6h
load(['Figure6\fig6_b']);

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
config.CameraPosition = [423.67252	514.25946	-440.86084];
config.CameraUpVector = [-0.034519054	-0.66054589	-0.75005031];

% config.ScaleFactors = [1,1,ratio_reso];

h = volshow(refocus_volume_resize_rescale(140:615,130:605,:,:),Parent=config);














