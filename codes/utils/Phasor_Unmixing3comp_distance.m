function [f1,f2,f3]=Phasor_Unmixing3comp_distance(Y,A1,A2,A3)
% [U1_tau,U2_tau,U3_tau] = Phasor_Unmixing3comp(G_tau+1i*S_tau,G_unmix0(1)+1i*S_unmix0(1),G_unmix0(2)+1i*S_unmix0(2),G_unmix0(3)+1i*S_unmix0(3));

if nargin==2
    A3 = A1(3);
    A2 = A1(2);
    A1 = A1(1);
end

M = [real(A1) real(A2) real(A3); imag(A1) imag(A2) imag(A3); 1 1 1];
N = cat(1, real(Y), imag(Y), ones(1,size(Y,2)));

f = M\N;
f1 = f(1,:);
f2 = f(2,:);
f3 = f(3,:);
end