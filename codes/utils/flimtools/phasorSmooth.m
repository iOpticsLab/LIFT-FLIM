function [SS,GG] = phasorSmooth(SS,GG,eb,ti,ga)
% eb is size of medfilt2 matrix (3 in simFCS, 5 for Xtreme)
% ti is number of times it is to be applied
% ga is a flag in order to do median(0), mean(1) or gaussian(2) filtering. 
%    defaulted to 0
if(nargin<5),ga=0;end

switch ga
    case 0
        vec=[eb,eb];
    case 1
    filtre=ones(eb,eb)/eb/eb;
    case 2
    filtre=fspecial('gaussian',eb,ti);
end
if(ga==0)
for jj=1:size(SS,3)
for ii=1:ti
    SS(:,:,jj)=medfilt2(SS(:,:,jj),vec);
    GG(:,:,jj)=medfilt2(GG(:,:,jj),vec);
end
end
else
for jj=1:size(SS,3)
for ii=1:ti
    SS(:,:,jj)=conv2(SS(:,:,jj),filtre,'same');
    GG(:,:,jj)=conv2(GG(:,:,jj),filtre,'same');
end
end
end
end