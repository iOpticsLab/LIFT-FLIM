function [S,G,a,b] = phasorFilterIntensity(S,G,I,thresh)

for zz=1:size(S,3)
[a,b]=find(I(:,:,zz)<=thresh);
for ii=1:length(a)
    
   S(a(ii),b(ii),zz)=NaN;
   G(a(ii),b(ii),zz)=NaN;
   
end
end


end