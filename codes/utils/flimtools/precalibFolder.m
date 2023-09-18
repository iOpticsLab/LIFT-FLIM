function [phasediff,modfac] = precalibFolder(folder,chtags)
RF='calib';
RF=[folder filesep RF];
if(ischar(chtags)),chtags={chtags};end
if(exist(folder,'dir')==0),error('folder does not exist!');end
if(exist(RF,'dir')==0),mkdir(RF);end

files=[dir([folder filesep '*.R64']);dir([folder filesep '*.fbd'])];
if(isempty(files)),error('no lifetime files found!');end
calib=zeros(length(files),1);
chans=zeros(length(files),length(chtags));
for ii=1:length(files)% find relevant channels and calib file

       % disp([' ' niceDigits(ii,2) ' - ' files(ii).date ' - ' niceDigits(round(files(ii).bytes/1e6),3) 'MB - ' files(ii).name]);
        aux=files(ii).name;

    if(contains(lower(aux),'calib')),calib(ii)=1;end
    for jj=1:length(chtags)
        if(contains(lower(aux),lower(chtags{jj}))),chans(ii,jj)=1;end
    end
end

    for jj=1:length(chtags)
  

            arxiu=files(find(chans(:,jj)==1)).name;

        disp(['For calibration of channel ' chtags{(jj)} ' using: ' arxiu '. \n']);
        names={'alexa647','alexa 647','atto647','atto 647','cy5','cy 5','coumarin6','cumarin6','coumarin 6','cumarin 6','rhodamine110','rodamine110','rhodamine 110','rodamine 110','fluorescein','rhodamine6g','rodamine6g','rhodamine 6g','rodamine 6g','gfp','rh110','rhodamine6g','rodamine6g','rhodamine 6g','rodamine 6g','rh6g','rh 6g','r6g','r 6g','rho6g','atto488','atto 488','rho110'};
        lifetimes=[1,1,1,1,1,1,2.5,2.5,2.5,2.5,4,4,4,4,4,4.1,4.1,4.1,4.1,3.2,4,4.08,4.08,4.08,4.08,4.08,4.08,4.08,4.08,4.08,4.1,4.1,4];
        lifetime=0;
        for ii=1:length(lifetimes)
            if(contains(lower(arxiu),names{ii}))
                lifetime=lifetimes(ii);
            end
        end
        if(lifetime==0), error('Could not determine reference lifetime.');end
        fprintf(['\b\b\b (' num2str(lifetime) 'ns). \n']);
        if(exist([RF filesep 'calibData.mat'],'file'))
            load([RF filesep 'calibData.mat']);
        else
            ensenya(['Calibration file ' arxiu]);
            [phasediff0,modfac0] = getCalibration2(arxiu,folder,lifetime,0,1,[]);
            phasediff(jj)=phasediff0;modfac(jj)=modfac0;
        end
    end
    save([RF filesep 'calibData.mat'],'phasediff','modfac');
    
end