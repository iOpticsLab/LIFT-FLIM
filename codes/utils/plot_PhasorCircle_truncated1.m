function plot_PhasorCircle_truncated1(timex,mod_freq,flag)

if nargin <2
    mod_freq = 1;
end

hold on
clear gg ss
k = 1;
for taaa = 0:0.01:1000
timetemp = (exp(-timex*1/taaa));
if flag ==1
    timetemp = norm1(timetemp);
end
timetemp(isnan(timetemp))=0;
[gg(k),ss(k)] = PhasorTransform(timetemp.^(mod_freq),2,1); % row vector
k = k+1;
end
plot(gg,ss,':k','LineWidth',1);

end