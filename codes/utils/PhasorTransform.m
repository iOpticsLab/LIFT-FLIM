function [G,S,Ph,M]=PhasorTransform(A,dim,Harmonic,gs_shift)

if nargin<4
    gs_shift = 0;
    if nargin<3
        Harmonic = 1;
        if nargin<2
            dim = 1;
        end
    end
end

gf=fft(A,[],dim);

switch dim
    case 1
        gf=conj(gf(Harmonic+1,:,:,:)./gf(1,:,:,:))+gs_shift;
    case 2
        gf=conj(gf(:,Harmonic+1,:,:)./gf(:,1,:,:))+gs_shift;
    case 3
        gf=conj(gf(:,:,Harmonic+1,:)./gf(:,:,1,:))+gs_shift;
    case 4
        gf=conj(gf(:,:,:,Harmonic+1)./gf(:,:,:,1))+gs_shift;
end

G = real(gf);
S = imag(gf);
Ph=atan2_2pi(S,G);
M=(sqrt(S.^2+real(gf).^2));
end