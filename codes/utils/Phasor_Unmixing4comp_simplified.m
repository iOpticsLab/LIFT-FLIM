function [f]=Phasor_Unmixing4comp_simplified(Gtemp,Stemp,G0,S0,Gknown, Sknown,FF)  % row is the different G values

M = [G0;S0;1 1 1];
N = cat(1,(Gtemp-FF.*Gknown)./(1-FF), (Stemp-FF.*Sknown)./(1-FF), ones(1,numel(FF)));

f = M\N;
f(f<0) = 0;
f(f>1) = 1;
f = f./sum(f,1).*(1-FF); % output amplitude

end