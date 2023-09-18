function y = DoubleGenLogistic_fx(x,I1minus,I1plus,I2plus,shift1,Growth1,n1,shift2,Growth2,n2)

y2 = I1minus + (I1plus - I1minus)./(1+exp(-Growth1.*(x-shift1))).^(1./n1);
y = y2  + (I2plus - y2)./(1+exp(-Growth2.*(x-shift2))).^(1./n2);

end