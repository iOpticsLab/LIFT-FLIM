function [vol,his,hea] = fbdRead2(file,path,verb,chan)
% Read flimbox data file
% Parameters
% file is a string with the file name
% path is the path to the file (defaulted to current folder)
% verb is a flag to display progress in command window (defaulted to 0)
% chan is a flag to specify read only channel (defaulted to 0 -all-).
% Returns
% vol is a stack of images vol with the 4th dimension being the channel
% his is a histogram of counts for each pixel with the 4th dimension being the phase and the 5th dimension being the channel
% hea is a struct with the header from the fbd file

if((nargin<4)||(isempty(chan))),chan=0;end
if((nargin<3)||(isempty(verb))),verb=0;end
if((nargin<2)||(isempty(path))),path=pwd;end
% path(path=='/')='\';
if(path(end)==filesep),path=path(1:end-1);end
if(strcmp(lower(file(end-3:end)),'.fbd')==0),file=[file '.fbd'];end
aux=dir([path filesep file]);
if(isempty(aux)),error('Cannot find file');end
tamany=round(1e-6*aux(1).bytes);

if(verb==1),tic;ensenya(['Opening fbd (' num2str(tamany) 'MB).']);end
singlechannel=-1;


fid = fopen([path filesep file],'r');
bits = fread(fid,Inf,'*ubit1');
fclose(fid);




L = length(bits);
L_word_header = 8;
L_header_bytes = 32768;
L_header = L_header_bytes*8;


header=bits(1:L_header);
header=decodebits(reshape(header,[L_word_header,L_header/L_word_header]));
header=char(header);
header=xml2struct(header);
if(isempty(fieldnames(header)))% attempt to read xml file
    try
        xml=dir([path filesep file(1:find(file=='$')-1) '*.xml']);
        fid=fopen([path filesep xml(1).name],'r');
        info=char(fread(fid,Inf,'char')');
        fclose(fid);
        header=xml2struct(info);
        
    catch
         
        try
          header = decodeFBDheaderEnrico(bits(2^13+1:2^13+2500));  
          header.ExcitationFrequency=header.laserfrequency*header.laserfactor;
          header.ScanLineLeftBorder=header.xtartingpixel;
          header.ScanLineLength=header.linelinegth;
          
          header.DecoderName='8w32fifo';% achtung nomes funciona per aquest firmware%%%%%%%%%%%%%%%%%%%
          
            enricocode=file(find(file=='$')+1:find(file=='$')+4);
            switch enricocode(1)% this part is useless, enrico does not use this any longer
                case 'A',header.YPixels=64;header.XPixels=header.YPixels;
                case 'B',header.YPixels=128;header.XPixels=header.YPixels;
                case 'C',header.YPixels=256;header.XPixels=header.YPixels;
                case 'D',header.YPixels=320;header.XPixels=header.YPixels;
                case 'E',header.YPixels=512;header.XPixels=header.YPixels;
                case 'F',header.YPixels=640;header.XPixels=header.YPixels;
                case 'G',header.YPixels=800;header.XPixels=header.YPixels;
                case 'H',header.YPixels=1024;header.XPixels=header.YPixels;
            end
%%%%%%%%%%%%%%%%%%%%% ASK ENRICO FOR DWELL TIME INDEX  *********8
             header.PixelDwellTime=32;% in ms %%%% override here for diver
            header.PixelDwellTime=header.PixelDwellTime*1e-3;
        
        catch
        % solucio guarra per obrir spartan3 del sasha
       gg=0;
        end        
    end
end
if(isempty(fieldnames(header))),error('header makes no sense');end
%%% constants that (may) depend on the fbf6 file
switch header.DecoderName
    case '8w32fifo'
        L_word = 32;
        Flags_Ch = [1,5,9,13];
        Range_windows = [2:4;6:8;10:12;14:16];
        Range_Phase = 17:24;
        Range_Time = 25:29;
        Flag_Frame = 31;
        CH=4;% total number of possible channels
    case '4w16fifo'    % this aint working, have to ask for the codification for spartan3    
            L_word = 16;
            Flags_Ch = [1,4];
            Range_windows = [15:16;3:4];
            Range_Phase = 5:10;
            Range_Time = 12:14;
            Flag_Frame = 9;
            CH=2;% total number of possible channels
            
%              header.YPixels=255;header.XPixels=256;
%             header.ExcitationFrequency=79985280;
%             header.PixelDwellTime=.020;header.YPixels=256;header.XPixels=header.YPixels;
%             header.ScanLineLeftBorder=34;header.ScanLineLength=324;
%%%%% added a mano
    otherwise
        error('unkown decoder');
end
chori=1;% first channel to read, used to access specific channel only
chfin=CH;% last channel to read, used to access specific channel only


if(verb==1),ensenya('Reading data.');end

data=reshape(bits,[L_word, L/L_word]);
clear bits;
data=data(:,L_header+1:end);

Channels = data(Flags_Ch,:);
aux=find(sum(Channels,2)>0);
chori=min(aux);chfin=max(aux);
CH=numel(chori:chfin);
if(chan~=0),CH=length(chan);chori=chan(1);chfin=chan(end);end
Channels=Channels(chori:chfin,:);

%mm=memory;disp(['Usage: ' niceDigits(round(100*mm.MemUsedMATLAB/mm.MemAvailableAllArrays),3) '%']);

Phase = decodebits(data(Range_Phase,:));
Time = decodebits(data(Range_Time,:));
%Window = decodebits(data(Range_windows,:));
Window = zeros(CH,size(data,2));
for ii=chori:chfin
    Window(ii-chori+1,:)=decodebits(data(Range_windows(ii,:),:));
end

frams=find(data(Flag_Frame,:)==1);
if(isempty(frams)),error('No frame flag in FBD file.');end
clear data;



tmp=Phase+(256*Window/2^size(Range_windows,2));
photonPhase=255-mod(tmp,256);
%canal=1;ed=[0:1:2^length(Range_Phase)];figure,bar(ed,histc(photonPhase(canal,find(Channels(canal,:)==1)),ed));%set(gca,'YScale','log')

clear Window;clear tmp;

freq=header.ExcitationFrequency;
DT=header.PixelDwellTime;

units=255/256/freq;
% pixoff=header.ScanLineLeftBorder;


macroTime=zeros(size(Time));

TimeOverf=0;
timeoff=2^length(Range_Time);
phaseoff=2^length(Range_Phase);
OverOff=timeoff*phaseoff;
Tiprev=-1;
for jj=1:length(Time)
    Ti=(Time(jj)*phaseoff)+Phase(jj);
    TT=((TimeOverf*OverOff)+Ti)*1e3*units;
    % T2=(((pulse-1)*timeoff)+Time(jj))*1e3*units; 
    if(Ti==0)
        if(Ti<=Tiprev)% check overflow count
            TimeOverf=TimeOverf+1;%
        end
    end
    macroTime(jj)=TT;%real time in milliseconds  ??????
    Tiprev=Ti;
end
%%
[macroTime,ord]=sort(macroTime);
photonPhase=photonPhase(:,ord);
Channels=Channels(:,ord);
%%
clear Phase;clear Time;


frams=[1 frams];frames=numel(frams);frams=[frams length(macroTime)];
frameTime=macroTime(frams);
lineL=header.ScanLineLength;
lines=header.YPixels;
columns=header.XPixels;
framesize=lineL*lines;


photonPix=-1*ones(size(macroTime));

first=1;%if(skip==1),first=2;end
% slow option recover individual frames
    for jj=first:frames
        range=[frams(jj)+1:frams(jj+1)];
        thisframe=macroTime(range);
        if(~isempty(thisframe))

            photonPix(range)=round((thisframe-frameTime(jj))/DT);
        
        end
    end
    clear macroTime;
    
    photonChannel=zeros(size(photonPhase));
    for ii=chori:chfin
        photonChannel(ii-chori+1,:)=Channels(ii-chori+1,:);
        %     photonChannel(ii,:)=(data(Flags_Ch(ii),:)==1);
        photonChannel(ii-chori+1,photonPix<=0)=0;
        photonChannel(ii-chori+1,photonPix>framesize)=0;
    end
    
    clear Channels;
    
    
    if(isfield(header,'ZPixels'))
        stacks=header.ZPixels;
    else
        stacks=1;
    end
    frames=round(frames/stacks)-1;% (aproximate) frames per stack

%  canal=2;ed=[0:1:2^length(Range_Phase)];
%  figure,bar(ed,histc(photonPhase(canal,find(Channels(canal,:)==1)),ed));
% figure,bar(ed,histc(photonPhase(canal,find(photonChannel(canal,:)==1)),ed));
%   
if(verb==1),ensenya('Building images.');end
      %%
      histbins=max(max(photonPhase))+1;
    vol=zeros(lines,columns,stacks,CH);
    his=zeros(lines,columns,stacks,histbins,CH);
    for cc=1:CH
     pph=photonPhase(cc,photonChannel(cc,:)==1);
     ppx=photonPix(photonChannel(cc,:)==1);
   
  %canal=cc;ed=[0:1:2^length(Range_Phase)];figure,bar(ed,histc(pph,ed));
      
     try
        endframes=[];startframes=[ppx(1)];top=max(ppx)*.95;bot=min(ppx)+(max(ppx)-min(ppx))*.06;
        % find steps that are jump from close to top to close to bot
        for ii=2:length(ppx)
            if(ppx(ii)<ppx(ii-1))
                if(ppx(ii)<bot)
                startframes=[startframes ii];
                end
                if(ppx(ii-1)>top)
                    %if(ppx(ii-1)-ppx(x)>top)
                endframes=[endframes ii-1];
                    %end
                end
            end
        end
         %  figure,plot(ppx);hold on,plot(startframes,ppx(startframes),'^');plot(endframes,ppx(endframes),'v');
        aux=startframes;startframes=zeros(size(endframes));
        for ii=length(endframes):-1:1% associate each endframe with previous start (discarding starts of cropped)
            gg=find(aux<endframes(ii),1,'last');
            if(~isempty(gg))
            startframes(ii)=aux(gg);
            end
        end
          %  figure,plot(ppx);hold on,plot(startframes,ppx(startframes),'^');plot(endframes,ppx(endframes),'v');
     
        out=[];
        for ii=length(startframes):-1:2% remove endframes sharing a starting (keep last)
            if(startframes(ii)==startframes(ii-1))
                out=[out ii-1];
            end
        end
        if(~isempty(out))
        startframes(out)=[];endframes(out)=[];
        end
       %  figure,plot(ppx);hold on,plot(startframes,ppx(startframes),'^');plot(endframes,ppx(endframes),'v');
       % figure,plot(endframes-startframes)
       difs=endframes-startframes;
       [difs2,ord]=sort(abs(diff(difs)),'descend');
       lastframeinstack=[sort(ord(1:stacks-1)) numel(endframes)];
            % reconstruct proper volume and hists        
              
            ll=header.ScanLineLength;rr=header.ScanLineLeftBorder-1;szx=header.XPixels+1;
            currentframe=1;currentstack=1;
            for ii=1:numel(ppx)% we can skip first photon, it is outside the frame, useful for computing difference with previous
                if(ii>=startframes(currentframe))
                    if(ii<=endframes(currentframe))
                        x=mod(ppx(ii),ll)-rr;
                        if((x>0)&&(x<szx))
                            y=ceil(ppx(ii)/ll);
                            vol(y,x,currentstack,cc)=vol(y,x,currentstack,cc)+1;
                            his(y,x,currentstack,pph(ii)+1,cc)= his(y,x,currentstack,pph(ii)+1,cc)+1;
                        end
                    else
                        if(~isempty(find(currentframe==lastframeinstack,1))),currentstack=currentstack+1;end% we just finished a last frame in a stack, increase index
                         currentframe=currentframe+1; % increase frame
                         if(currentframe>length(endframes)),break;end
                    end
                end
            end
            %              figure,imagesc(vol(:,:))
%              figure,imagesc(vol(:,:,2))
%              figure,imagesc(sum(his(:,:,2,:),4));
            
     end
    end
   hea=header;
end


