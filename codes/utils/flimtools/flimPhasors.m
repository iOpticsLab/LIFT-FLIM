function [S,G] = flimPhasors(T,n,framesize)
% T is a matrix of N (pix positions) by t (time bins) of photon counts
% n is the harmonic for the phasor decomposition (defaulted to 1)
% framesize is an optional 2 dimensional vector [n m] such that n*m=N to
% reshape S and G outputs.
% if framesize is specified, NaNs (from zero counts in pixel) are filtered
% out using neighbour values of S and G.
if(nargin<2),n=1;end
if(numel(unique(T))==1),
    warning('No data!');S=0;G=0;
else
    edph=[0:size(T,2)-1];
    w=2*3.1416/size(T,2);
    S=zeros(size(T,1),1);
    G=S;
    %N=S;% keep track of nans;
    for ii=1:size(T,1)
        
        decay=T(ii,:);
        D=sum(decay);
        
        S(ii)=sum(decay.*sin(n*w*edph))/D;
        G(ii)=sum(decay.*cos(n*w*edph))/D;
        
    end
    
    
    % phase=0;
    % while 1
    % phase=phase+.0628;
    %
    %  figure(44),clf;
    %  subNM(1,2,1,[.05 .09 .05 .09]);n=1;
    %  decay=sum(T,1);bar(NormArray(decay));hold on;
    %  plot(sin(phase+n*w*edph),'r');
    %  plot(cos(phase+n*w*edph),'b');
    %  h=plot(sin(phase+n*w*edph).*NormArray(decay),'r');set(h,'linewidth',2)
    %  h=plot(cos(phase+n*w*edph).*NormArray(decay),'b');set(h,'linewidth',2)
    %  niceplot;axis tight;title(['n=' num2str(n) ', S=' num2str(round(10000*sum(decay.*sin(phase+n*w*edph))/sum(decay))/10000) ', G=' num2str(round(10000*sum(decay.*cos(phase+n*w*edph))/sum(decay))/10000)]);
    %  subNM(1,2,2,[.05 .09 .05 .09]);n=2;
    %  decay=sum(T,1);bar(NormArray(decay));hold on;
    %  plot(sin(phase+n*w*edph),'r');
    %  plot(cos(phase+n*w*edph),'b');
    %  h=plot(sin(phase+n*w*edph).*NormArray(decay),'r');set(h,'linewidth',2)
    %  h=plot(cos(phase+n*w*edph).*NormArray(decay),'b');set(h,'linewidth',2)
    %  niceplot;axis tight;title(['n=' num2str(n) ', S=' num2str(round(10000*sum(decay.*sin(phase+n*w*edph))/sum(decay))/10000) ', G=' num2str(round(10000*sum(decay.*cos(phase+n*w*edph))/sum(decay))/10000)]);
    %  pause(.01);drawnow;
    % end
    if(nargin>=3)
        %    S=reshape(S,framesize(2:-1:1))';% flip size and transpose
        %    G=reshape(G,framesize(2:-1:1))';
        S=reshape(S,framesize);
        G=reshape(G,framesize);
        
        %%% check for NaNs
        mg=0;
        while(1)
            auxg=find(isnan(G));auxs=find(isnan(S));aux=unique([auxg;auxs]);
            if(isempty(aux)),break;end
            mg=mg+1;
            [G,S] = substnans(G,S,aux,mg);
        end
    end
end
end

function [G,S] = substnans(G,S,list,mg)
[a0,b0]=size(G);
[a,b]=ind2sub([a0,b0],list);
for kk=1:length(a)
    rgy=[a(kk)-mg:a(kk)+mg];rgy(rgy<1)=[];rgy(rgy>a0)=[];
    rgx=[b(kk)-mg:b(kk)+mg];rgx(rgx<1)=[];rgx(rgx>b0)=[];
    
    aux2=G(rgy,rgx);aux2(isnan(aux2))=[];
    G(a(kk),b(kk))=mean(aux2);
    aux2=S(rgy,rgx);aux2(isnan(aux2))=[];
    S(a(kk),b(kk))=mean(aux2);
    
end

end