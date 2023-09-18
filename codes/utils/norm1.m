% Normalize a vector 
function output = norm1(x)

x=single(x); 
x=x-min(x(:)); 
output=x./max(x(:)); 