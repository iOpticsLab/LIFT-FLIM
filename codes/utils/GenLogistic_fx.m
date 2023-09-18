function y = GenLogistic_fx(x,I1minus,I1plus,shift1,Growth1,n1)

y = I1minus + (I1plus - I1minus)./(1+exp(-Growth1.*(x-shift1))).^(1./n1);

end