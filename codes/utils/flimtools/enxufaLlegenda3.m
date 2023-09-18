function [Im] = enxufaLlegenda3(Im,res,col,pos,sty,txt,force)
% Incrusta barra d'escala tenint en compte que
% cada pixel fa res micres. L'escala es pinta amb color col i estil sty 
% (0 per linia simple, 1 per linia amb extrems, 2 per barra tallada, 3 per barra).
% pos pot ser un de 'NE','NW','SE','SW' (default es 'SE')
% txt is a show text flag (default to 1)
% force is a value in microns to force the scale bar

if(nargin<7),force=0;end
if(nargin<6),txt=1;end
if(nargin<5),sty=0;end
if(nargin>=4),pos=upper(pos);
    if(strcmp(pos,'SE')==1),pos=1;end
    if(strcmp(pos,'SW')==1),pos=2;end
    if(strcmp(pos,'NE')==1),pos=3;end
    if(strcmp(pos,'NW')==1),pos=4;end
    if(ischar(pos)),pos=1;end
end
if(nargin<4),pos=zonabuida(Im);end
if(nargin<3),col=255;end
if(nargin<2),error('falten arguments');end

T=255;
if(max(max(max(Im)))<=1),T=1;end
if(max(max(max(Im)))>256),T=max(max(max(Im)));end

    if(strcmp(class(Im),'uint8')==1),cla='uint8';end
    if(strcmp(class(Im),'uint16')==1),cla='uint16';T=2^16;end
    if(strcmp(class(Im),'int16')==1),cla='int16';T=2^16;end
    if(strcmp(class(Im),'double')==1),cla='double';end

Im=double(Im);
[a,b,c]=size(Im);
if(max(col)>1),col=col/T;end
if(size(col,2)~=c),col=ones(1,c)*col(1);end


tamany=[a,b].*[res,res];%en micres
unitats='?m';
if(tamany(2)<3),unitats='nm';res=res*1000;end
marge=round([b/10 b/2]);%enpix

accepted=[.01,.02,.05,.1,.2,.5,1,2,5,10,20,50,100,200,500,1000,2000,5000,10000,20000,50000,100000,200000,500000,1000000]/res;
ind=find((accepted<=marge(2))&(accepted>marge(1)),1,'first');
if(force>0)
    longitud=round(force/res);
else
longitud=round(accepted(ind));
end
%F=ceil(a/20);
G=ceil(a/200);
if(pos>2)% a dalt
barraY=3*G:4*G;
palsY=2*G:5*G;
Factoret=-1;
else  % a baix
barraY=a-4*G:a-3*G;
palsY=a-5*G:a-2*G;
Factoret=1;
end  
if(mod(pos,2)==1) % dreta
barraX=b-longitud-2*G:b-2*G;
palsX=[b-longitud-2*G:b-longitud-G,b-3*G:b-2*G];
else     % esquerra
barraX=4*G:4*G+longitud;
palsX=[2*G:3*G,longitud+G:longitud+2*G];
end




for ii=1:c
if(sty<=1)
Im(barraY,barraX,ii)=col(ii)*T;
end
if(sty>=1)
Im(palsY,palsX,ii)=col(ii)*T; 
end
if(sty==2)
 Im(palsY(1):palsY(1)+numel(barraY)-1,barraX,ii)=col(ii)*T;
 Im(palsY(end)-numel(barraY)+1:palsY(end),barraX,ii)=col(ii)*T;  
 gru=round(numel(palsX)/2);
 inc=longitud/round(accepted(ind)*res);
 for jj=1:round(accepted(ind)*res)-1
     Im(palsY,palsX(1)+inc*jj:palsX(1)+inc*jj+gru,ii)=col(ii)*T; 
     
 end
end
if(sty==3)
Im(palsY,barraX,ii)=col(ii)*T;
end
end
centre=round([mean(barraY) mean(barraX)]);
centre(1)=centre(1)-G*Factoret;

numeret=num2str(round(accepted(ind)*res));
numeret=num2str(numeret);
%Z=text2im([num2str(numeret) '?m']);
if(sty==2)
if(pos>=2)
    centre(1)=centre(1)+floor(length(barraY)*.5);
else    
    centre(1)=centre(1)-round(length(barraY)*.5);
end
end
va='bot';
if(pos>2),va='top';end
if(txt==1)
     Im=textIm(centre(2),centre(1),[numeret unitats],Im,...
      'fontsize',length(barraY)*6,'fontname','verdana','textcolor',col*T,...
      'horizontalalignment','center','verticalalignment',va,'blending','on');
end
 eval(['Im=' cla '(Im);']);  
   
%figure;imagesc(1);colormap([0 0 0]);
%text(1,1,[ '1 2 3 4 5 6 7 8 9 0 \mum'],'color',[1 1 1],'fontsize',14,'HorizontalAlignment','center');




end
function [pos] = zonabuida(Im)
%averigua la cantonada on hi ha menys informacio
Im=sum(Im,3);
[a,b]=size(Im);
cnts=[0,0,0,0];
sz=round([a,b].*[.1 .2]);
ors=[a-sz(1),b-sz(2);a-sz(1),1;1,b-sz(2);1 1];
fns=[a,b;a,sz(2);sz(1),b;sz(1),sz(2)];
for ii=1:4
   ret=Im(ors(ii,1):fns(ii,1),ors(ii,2):fns(ii,2));
   cnts(ii)=sum(sum(ret))/numel(ret);
end
[~,pos]=min(cnts);

end