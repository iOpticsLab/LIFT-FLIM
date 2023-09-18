function [IDX] = sortIDX(IDX,X)

vals=unique(IDX);
for kk=1:numel(vals)
   IDX(IDX==vals(kk))=kk; 
end
vals=unique(IDX);
pos=zeros(length(vals),1);N=pos;% nombre delements
for kk=1:numel(vals)
    aux=find(IDX==vals(kk));
   pos(kk)=aux(1);
   N(kk)=numel(aux);% nombre delements
end
% pos=sort(pos); % ordre daparicio
[~,ord]=sort(N,'descend');pos=pos(ord);% nombre delements
for kk=1:numel(vals)
   w1=find(IDX==vals(kk));
   w2=find(IDX==IDX(pos(kk)));
   IDX(w1)=IDX(pos(kk));
   IDX(w2)=vals(kk);    
end

if(nargin>1)&&(numel(unique(IDX))<4)
  vals=unique(IDX);
pos=zeros(length(vals),1);N=pos;% coordenada vertical
for kk=1:numel(vals)
    aux=find(IDX==vals(kk));
   pos(kk)=aux(1);
   N(kk)=mean(X(aux,2));% coordenada vertical
end  
  [~,ord]=sort(N,'descend');pos=pos(ord);% coordenada vertical
for kk=1:numel(vals)
   w1=find(IDX==vals(kk));
   w2=find(IDX==IDX(pos(kk)));
   IDX(w1)=IDX(pos(kk));
   IDX(w2)=vals(kk);    
end

end

end