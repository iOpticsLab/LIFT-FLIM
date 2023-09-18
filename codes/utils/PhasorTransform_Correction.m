function [Gc,Sc,Pc,Mc] = PhasorTransform_Correction(G,S,dP,xM)

P=atan2_2pi(S,G);
M=(sqrt(S.^2+G.^2));

Pc=P-dP;
Mc=M./xM;
Sc = Mc.*sin(Pc);
Gc = Mc.*cos(Pc);
end