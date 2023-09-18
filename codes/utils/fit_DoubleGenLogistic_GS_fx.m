function [param,func_g,func_s]=fit_DoubleGenLogistic_GS_fx(x,g,s,Display,param0)

if nargin<5
if nargin<4
    Display = 0;
end
g_plusInf1   = g(round(length(g)/2));
g_minusInf1  = g(1);
g_plusInf2   = g(end);
s_plusInf1   = s(round(length(s)/2));
s_minusInf1  = s(1);
s_plusInf2   = s(end);
center1      = x(round(length(g)/3));
center2      = x(round(length(g)/3*2));
steepness1   = 1/length(g)*30;
steepness2   = 1/length(g)*30;
n1           = 1;
n2           = 1;
%f_minusInf2
param0 = [g_minusInf1,g_plusInf1,g_plusInf2,s_minusInf1,s_plusInf1,s_plusInf2,center1,steepness1,n1,center2,steepness2,n2];
else
    if isstruct(param0)
        param0 = [param0.g_minusInf1,param0.g_plusInf1,param0.g_plusInf2,param0.s_minusInf1,param0.s_plusInf1,param0.s_plusInf2,param0.center1,param0.steepness1,param0.n1,param0.center2,param0.steepness2,param0.n2];    
    end
end

options = optimset('MaxIter',1000*1000*length(x),'MaxFunEvals',1000*1000*length(x));
[param1, ~]=fminsearch(@(Param)sum(sum((func_fit_g(x,Param)-g).^2+(func_fit_s(x,Param)-s).^2)),param0,options);
func_g = func_fit_g(x,param1);
func_g0 = func_fit_g(x,param0);
func_s = func_fit_s(x,param1);
func_s0 = func_fit_s(x,param0);

if Display == 1
    
    figure
    subplot(1,2,1)
    hold on
    plot(x,g)
    plot(x,func_g,'--r')
    plot(x,func_g0,'-m')
    Figure_Format_Graph
    subplot(1,2,2)
    hold on
    plot(x,s)
    plot(x,func_s,'--r')
    plot(x,func_s0,'-m')
    Figure_Format_Graph
    
end
param.g_minusInf1 = param1(1);
param.g_plusInf1 = param1(2);
param.g_plusInf2 = param1(3);
param.s_minusInf1 = param1(1+3);
param.s_plusInf1 = param1(2+3);
param.s_plusInf2 = param1(3+3);
param.center1 = param1(4+3);
param.steepness1 = param1(5+3);
param.n1 = param1(6+3);
param.center2 = param1(7+3);
param.steepness2 = param1(8+3);
param.n2 = param1(9+3);


end