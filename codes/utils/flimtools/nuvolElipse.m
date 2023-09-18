function [e,veps,a,b,inc] = nuvolElipse(da,conf)
if(nargin<2),conf=.95;end
try
   fac=sqrt(chi2inv(conf,2));
catch
   fac=2.22; 
end
   Mu=mean(da);
    X0=da-Mu;
    [veps,D]=eig(cov(X0));
    [vaps,ord]=sort(diag(D),'descend');%ordena per vaps
    D = diag(vaps);
    veps=veps(:,ord);
    inc=-atan2(veps(2,1),veps(1,1));
    
    ang=linspace(0,2*3.1416,100);
    

a=fac*sqrt(vaps(1));
b=fac*sqrt(vaps(2));

e=[a*cos(ang);b*sin(ang)];
    
    e=[cos(inc) sin(inc);-sin(inc) cos(inc)]*e;
e(1,:)=e(1,:)+Mu(1);
e(2,:)=e(2,:)+Mu(2);
%veps=veps.*[a,b;a,b];
end