%% Figure 5 

%% 
clc;clear;
close all;

load(['Figure5\fig5']);

%% figure a-b
figure;imagesc(BlurredInten,[0 1]);colormap gray;axis off equal;% blurred intensity
figure;imagesc(lifeinten,[0 1]);colormap gray;axis off equal;% refocused intensity

%% figure d-e

inten=norm1(lifeinten);
uu=colormap('jet');
lifecolor=uu(:,:); %  jet colormap 9 37 63 77 min(min(ll2))
%-------------------------
ll2=lifevalue;
%---------------------------
maxlife=2.5;minlife=1.5;gtlifemask = ones(size(ll2));gtlifemask(ll2<0.5|ll2>4)=0;
interv=(maxlife-minlife)/(256);  % lifetime intervals
index=floor((ll2-minlife)/interv);index(index>256)=256;index(index<1)=1;
[a,b] = size(inten);
LIFEMAP_M=zeros(a,b,3);

for k=1:a
    for j=1:b  
         LIFEMAP_M(k,j,:)=inten(k,j)*lifecolor(index(k,j),:)*gtlifemask(k,j)*3;% green
    end
end

figure;
hm = axes;
imagesc(hm,LIFEMAP_M,'alphadata',1,[minlife,maxlife]);
axis off equal
u1=colormap('jet');colormap(hm,u1);
cbm=colorbar(hm); cbm.Label.String='Lifetime(ns)';  cbm.FontSize=16;%cbm.FontWeight='bold';

% Zoom in region
Xrange = [63:480];Yrange = [356:733];
figure;
hm = axes;
imagesc(hm,LIFEMAP_M(Yrange,Xrange,:),'alphadata',1,[minlife,maxlife]);
axis off equal
u1=colormap('jet');colormap(hm,u1);
%% figure i
rgt = zeros(size(unmixtumor));

rlife1=unmixtumor;
rlife2=unmixnormal;

LIFEMAP=ind2rgb(floor(rgt),gray); % final map rgb image
[a,b,~]=size(LIFEMAP);

for k=1:a
    for j=1:b  
         LIFEMAP(k,j,:)=inten(k,j)*[rlife1(k,j) rlife2(k,j) 0]*2;%
    end
end
 
figure;imagesc(LIFEMAP);axis off equal;


%% figure h
load(['densityphasor']);

% output phasorplot heatmap
Gl_cluster(Gl_cluster<0) = 0;Sl_cluster(Sl_cluster<0) = 0;
fov2 = [0,max(1,max(Gl_cluster));0,max(0.5,max(Sl_cluster))]; 
figsize = [256,128];
[I,tk1,tk2,remapping] = hist2D(Gl_cluster,Sl_cluster,figsize,fov2);% output phasorplot heatmap
%  G---cols cor, S---rows cor ,[Xreso, Yreso] ; [Xrange, Yrange]-- [minG maxG;minS maxS].
% %     tk1--Xtick; tk2--Ytick  are tick position (row1) and value (row2) 
%       [128 256] is a 1x2 vector specifying output image size (and therefore binning in phasor space).
%       [0,1;0,.5] is a 2x2 matrix of field of view: [minG maxG;minS maxS].
% remapping: [Scor,Gcor,]  [rows cor, cols cor]
timelength = 14;
timex=0:timelength-1;
[gg,ss] = GS_PhasorCircle_truncated(timex,1,0);
[I1,~,~,remapping1] = hist2D(gg,ss,figsize,fov2);% output phasor circle heatmap

% figure;plot(Gl_cluster,Sl_cluster,'.'); % scatter plot axis ij off
% figure;plot(gg,ss,'.'); % scatter plot axis ij off

photonthresh = 5;
I(I<photonthresh) = 0;

figure;imagesc(I,[0 max(I(:))]);colormap(superjet(255,'wSbZctglyGorrmp'));hold on;
c = colorbar;c.Label.String='Counts';  c.FontSize=16;c.FontWeight='bold';

hold on;plot(remapping1(:,2),remapping1(:,1),'-k','LineWidth',1);axis ij off 

[probsall,clusteridx] = max(fs',[],2); % cluster index 
% choose the cluster with the higher probability and assign that cluster to the pixel.

colors=superjet(2,'rg');

K=2;
X = [Sl_cluster,Gl_cluster];

probs = fs';

[PP0,tk1,tk2,remap] = hist2D(X(:,2),X(:,1),figsize,fov2);% output phasorplot heatmap
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

















