function [J] = performance(IDX,ID)

tru=unique(ID);
val=unique(IDX);
N=length(ID);
conta=zeros(length(tru),length(val));
quins=[1:length(val)];
J=0;
for ii=1:length(tru)
    ref=find(ID==tru(ii));    
    for jj=quins
       thi=find(IDX==val(jj)); 
       conta(ii,jj)=numel(intersect(ref,thi));
    end
    [v,q]=max(conta(ii,:));%quins(quins==q)=[];
end
for ii=1:length(tru)
    [a,b]=find(conta==max(max(conta)),1,'first');     
   J=J+conta(a,b);
   conta(:,b)=0; conta(a,:)=0;
end
J=J/N;

end