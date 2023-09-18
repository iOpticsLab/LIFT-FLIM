function [] = phasorPlotPoints(coords,cols,mksz)
freq=8e7;%nomes per si coords son lifetimes
if(nargin<3),mksz=22;end
if(nargin<2),cols=superjet(size(coords,1)+1);end
nc=size(cols,1);
if(ischar(cols)),if(size(cols,2)>size(cols,1)),cols=cols';nc=length(cols);end;end
if(ischar(cols)),cols=superjet(length(cols),cols);end
if(nc<size(coords,1)),colsN=[];for ii=1:ceil(size(coords,1)/nc),colsN=[colsN;cols];end;cols=colsN;end
if(size(coords,2)==1)% son lifetimes i no coordenades s,g
    omega=2*3.1416*freq*1e-9;
   coords(:,2)=1./(1+((omega*coords(:,1)).^2));
   coords(:,1)=sqrt(coords(:,2)-(coords(:,2).*coords(:,2)));
end
% 
% fov=[0 1;0 .5];
%  PP=phasorPlot(coomin([1,3]),coomin([2,4]),[256 512],11,fov);
% % % top-left top-right ; bot-left bot right
%  xI=[fov(1,:);fov(1,:)];
%  yI=[fov(2,2) fov(2,2);fov(2,1) fov(2,1)];
%  zI=[0 0; 0 0];
% surf(xI,yI,zI,'CData',I,'FaceColor','texturemap','EdgeColor','none');
 hold on;
for ii=1:180
      h=plot(.5*[1+cos((ii)*3.1416/180) 1+cos((ii-1)*3.1416/180)],.5*[sin((ii)*3.1416/180) sin((ii-1)*3.1416/180)]);set(h,'color','k');   
end
xl=xlim();yl=ylim();
h=line(xl,[yl(1) yl(1)]);set(h,'color','k');
h=line(xl,[yl(2) yl(2)]);set(h,'color','k');
h=line([xl(1) xl(1)],yl);set(h,'color','k');
h=line([xl(2) xl(2)],yl);set(h,'color','k');
%colormap(superjet(255,'wSbZctglyGorrmp'));colorbar();
%cols=superjet(8,'rgbergbe');cols(size(positions,1)/2+1:end,:)=cols(size(positions,1)/2+1:end,:)*.5;
for ii=1:size(coords,1)
    h=plot(coords(ii,2),coords(ii,1),'.');set(h,'markersize',mksz+3,'color','k')
    h=plot(coords(ii,2),coords(ii,1),'.');set(h,'markersize',mksz,'color',cols(ii,:))
end
niceplot;view(0,90);%xlim([0,1]);ylim([0,.5]);
axis image;grid off;

end