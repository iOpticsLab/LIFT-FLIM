function [phasediff,modfac] = getCalibration2(file,path,lifetime,show,harms,chan)
if(nargin<6),chan=[];end
if(nargin<5),harms=1;end% harms only relevant from fbd files not refs
if(nargin<4),show=0;end
sz=[512 512];
ebutton=7;ntimes=7;fov=[-1,1;-1,1];remove=floor(ebutton/2)*(ntimes);%
% [~,T,~] = fbdReadStacks(file,path,show,0,chan);
if((strcmpi(file(end-2:end),'ref'))||(strcmpi(file(end-2:end),'r64')))%
    [FLIM,files]=refread([path filesep file]);
    %  IT=FLIM{1}(:,:,1);
    S0=FLIM{1}(:,:,3).*sin(FLIM{1}(:,:,2)*3.1416/180);
    G0=FLIM{1}(:,:,3).*cos(FLIM{1}(:,:,2)*3.1416/180);
    
    S=mean(mean(S0));
    G=mean(mean(G0));
    
        if(show==1)
            figure(23);
            subNM(1,2,1,.05);
            phasorPlotPoints([S,G],'r');
            xl=xlim();yl=ylim();
            title('Raw');
        end

        [s,g]=expectedPhasorPosition(lifetime,80000000,1);
        %[py,px]=phasorposition2pix([s,g],size(PhPl),fov);
        
        % get calibration
        phasediff(1)=atan2(s,g)-atan2(S,G);
        modfac(1)=sqrt((s*s)+(g*g))/sqrt((S*S)+(G*G));
        
        if(show==1)
            pha=atan2(S,G)+phasediff(1);
            mod=sqrt((S.*S)+(G.*G))*modfac(1);
            SS=mod.*sin(pha);GG=mod.*cos(pha);
            subNM(1,2,2,.05);
            phasorPlotPoints([SS,GG],'g');
            xlim(xl);ylim(yl);
            title('Calibrated');
        end
else
    [~,T,~] = fbdRead2(file,path,0,chan);
    
%     ed=[0:1:255];figure,bar(ed,permute(sum(sum(sum(T,4),2),1),[3,1,2]));%set(gca,'YScale','log')
%     figure,imagesc(sum(I(:,:,:,1),3));
    if(isempty(chan))
        [~,ch]=max(sum(sum(sum(sum(T,1),2),3),4));
    end
    T=permute(T(:,:,:,:,ch),[1 2 4 3]);
    T=sum(sum(T,1),2);
    [fil,col,win,~]=size(T);
    CH=1;
    phasediff=zeros(1,harms);
    modfac=zeros(1,harms);
    
    for harmonic=1:harms
        S=zeros(fil,col,CH);
        G=zeros(fil,col,CH);
        for ii=1:CH
            [Si,Gi] = flimPhasors(reshape(T(:,:,:,ii),[fil*col,win]),harmonic,[fil,col]);
            S(:,:,ii)=Si;
            G(:,:,ii)=Gi;
        end
        
        if(show==1)
            figure(23);
            subNM(harms,2,2*harmonic-1,.05);
            phasorPlotPoints([S,G],'r');
            xl=xlim();yl=ylim();
            title('Raw');
        end

        [s,g]=expectedPhasorPosition(lifetime,80000000,harmonic);
        %[py,px]=phasorposition2pix([s,g],size(PhPl),fov);
        
        % get calibration
        phasediff(harmonic)=atan2(s,g)-atan2(S,G);
        modfac(harmonic)=sqrt((s*s)+(g*g))/sqrt((S*S)+(G*G));
        
        if(show==1)
            pha=atan2(S,G)+phasediff(harmonic);
            mod=sqrt((S.*S)+(G.*G))*modfac(harmonic);
            SS=mod.*sin(pha);GG=mod.*cos(pha);
            subNM(harms,2,2*harmonic,.05);
            phasorPlotPoints([SS,GG],'g');
            xlim(xl);ylim(yl);
            title('Calibrated');
        end
    end
end
end