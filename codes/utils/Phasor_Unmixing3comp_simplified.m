function [f]=Phasor_Unmixing3comp_simplified(Gtemp,Stemp,G0,S0)  % row is the different G values

M = [G0;S0;1 1 1];
N = cat(1,Gtemp, Stemp, ones(1,numel(Gtemp)));

f = M\N;
f(f<0) = 0;
f(f>1) = 1;
f = f./sum(f,1); % output amplitude

end