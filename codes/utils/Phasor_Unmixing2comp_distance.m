function [f1,f2]=Phasor_Unmixing2comp_distance(Y1,A1,A2)
% Phasor_Unmixing2comp_distance(G_tau(Ch_vect_spectra)+1i*S_tau(Ch_vect_spectra),G_unmix0+1i*S_unmix0);
if nargin==2
    A2 = A1(2);
    A1 = A1(1);
end

[X,Y] = size(Y1);
if X>1&&Y>1
    Y1 = Y1(1:end);
end

M = [real(A1) real(A2); imag(A1) imag(A2); 1 1];
N = cat(1, real(Y1), imag(Y1), ones(1,size(Y1,2))); % num of components to be unmixed

f = M\N;
f1 = f(1,:);
f2 = f(2,:);

if X>1&&Y>1
    f1 = reshape(f1,X,Y);
    f2 = reshape(f2,X,Y);
end
end