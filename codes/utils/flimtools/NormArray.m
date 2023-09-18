function [A] = NormArray(A,f,f2)
% normalise an n-d array 
A=double(A);
if(nargin==1)
A=(A-min(A(:)))/(max(A(:))-min(A(:)));
end
if(nargin==2)
    rg=max(A(:))-min(A(:));
    f=rg*f;
    A=(A-f-min(A(:)))/(max(A(:))-2*f-min(A(:)));
    A(A<0)=0;A(A>1)=1;
end
if(nargin==3)
    rg=max(A(:))-min(A(:));
    f=rg*f;f2=rg*f2;
    A=(A-f-min(A(:)))/(max(A(:))-f-f2-min(A(:)));
    A(A<0)=0;A(A>1)=1;
end


end