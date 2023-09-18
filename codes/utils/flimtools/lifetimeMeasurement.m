function [microtimes] = lifetimeMeasurement(Np,Li)
% returns Np arrival times in ps drawn from a distribution with lifetime Li
T=12.5;%laser period in ns
% shift=round(0.5*T*1000*(1+rand(1)));
shift=6*1000;%override
Np=round(Np);
irf=1000;% std of gaussian for irf in ps


% bins=256;
sampres=1e8;
fac=ceil(-log(.001)*Li/T);% total numer of cycles allowed for tail to decay to 0.001


% prepare theoretical decay
t=[1:fac*T*1000];%in ps
fun=exp(-t/1000/Li);
fun=[zeros(1,shift),fun];
fun=fun(1:length(t));
% convolve by irf
ga=exp(-(t/irf).*(t/irf)/2);
ga=[ga(end:-1:1) ga];
ga=ga(find(ga>.001,1,'first'):find(ga>.001,1,'last'));
fun=conv(fun,ga,'same');
% % secondary peak in leica falcon
% if(0)
%     pw=333;
%   peak=exp(-((t-shift-8000)/pw).*((t-shift-8000)/pw)/2);
%   fun=fun+peak*max(fun)*.6;
% end
opt=0;
if(opt==1)% intuitive but slow - draw from cdf
    dist=cumsum(fun);dist=round(sampres*dist/max(dist));
    fot=sampres*rand(Np,1);microtimes=zeros(size(fot));
    for ii=1:Np
        microtimes(ii)=find(dist>=fot(ii),1,'first');
    end
else% fast montecarlo - throw points and keep if under curve
    cc=0;cc2=0;
    dist=fun;dist=dist/max(dist);L=length(dist);
    vec=rand(1e6,2);vec(:,2)=round(vec(:,2)*(L-1))+1;
    microtimes=zeros(Np,1);
    while(cc2<Np)
        cc=cc+1;
        if(cc>1e6)
            cc=1;
            vec=rand(1e6,2);vec(:,2)=round(vec(:,2)*(L-1))+1;
        end
        if(vec(cc,1)<dist(vec(cc,2)))
            cc2=cc2+1;
            microtimes(cc2)=t(vec(cc,2));
        end
    end
end

% figure,plot(t,fun)
% % figure,plot(t,dist)
% figure;histogram(microtimes);
for ii=1:fac
    microtimes(microtimes>T*1000)=microtimes(microtimes>T*1000)-T*1000;
end


end