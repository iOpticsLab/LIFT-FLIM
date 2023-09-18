function Im = weights2image(vol,W,id,cols,thres)

opt=2;
k=size(W,2);% num clusters
if(nargin<5),thres=zeros(1,k);end
vol=NormArray(vol);% intensity image
facsI=1*ones(1,k);
masks=zeros(size(vol,1),size(vol,2),k);
facs=zeros(1,k);
for kk=1:k
    aux=masks(:,:,kk);
    aux(id)=W(:,kk);
    masks(:,:,kk)=aux;% image with weights
   
end

 aux=vol.*masks;
 [~,aux]=max(aux,[],3);
 for kk=1:k 
     aux2=vol;
 aux2(aux~=kk)=0;
 aux2=NormArray(aux2)-thres(kk);
 aux2(aux2<0)=0;aux2=NormArray(aux2);
% max(max(aux2))*thres(kk)
    facs(kk)=max(max(aux2));% for renormalisation purposes
    vol(aux==kk)=aux2(aux==kk);
 end
 %facs=ones(1,k);% override renorm
%  facs=facs/max(max(facs));
Im=zeros(size(vol,1),size(vol,2),3);
if(opt==1)% remap each region to rgb separately
    for kk=1:k
        cmap=[linspace(0,cols(kk,1),256)',linspace(0,cols(kk,2),256)',linspace(0,cols(kk,3),256)'];
        aux=gray2rgb(vol.*masks(:,:,kk),cmap);
        Im=Im+facsI(kk)*aux/facs(kk);
    end
else % create color mask and apply as a whole (allowing to merge)
    pixcol=zeros(size(vol,1),size(vol,2),3);
    for kk=1:k
        cmap=[linspace(0,cols(kk,1),256)',linspace(0,cols(kk,2),256)',linspace(0,cols(kk,3),256)'];
        aux=gray2rgb(masks(:,:,kk),cmap);
        pixcol=pixcol+facsI(kk)*aux/facs(kk);
    end  
    pixcol=imgaussfilt(pixcol,size(pixcol,2)/128);
    Im=vol.*pixcol;
end
Im=NormArray(Im);
%Im(Im>1)=1;
end