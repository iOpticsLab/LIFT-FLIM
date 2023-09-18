function [param,func_g,func_s]=fit_GenLogistic_GS(x,g,s,Display,param0)

if nargin<5
if nargin<4
    Display = 0;
end
g_plusInf1   = g(round(length(g)/2));
g_minusInf1  = g(1);
s_plusInf1   = s(round(length(s)/2));
s_minusInf1  = s(1);
center1      = x(round(length(g)/3));
steepness1   = 2;
n1           = 0.5;
%f_minusInf2
param0 = [g_minusInf1,g_plusInf1,s_minusInf1,s_plusInf1,center1,steepness1,n1];
else
param0 = [param0.g_minusInf1,param0.g_plusInf1,param0.s_minusInf1,param0.s_plusInf1,param0.center1,param0.steepness1,param0.n1];    
end

options = optimset('MaxIter',1000*1000*length(x),'MaxFunEvals',1000*1000*length(x));
[param1, ~]=fminsearch(@(Param)sum(sum((func_fit_g_gen(x,Param)-g).^2+(func_fit_s_gen(x,Param)-s).^2)),param0,options);
func_g =  func_fit_g_gen(x,param1);  % optimized
func_g0 = func_fit_g_gen(x,param0);  % initial
func_s =  func_fit_s_gen(x,param1);  % optimized
func_s0 = func_fit_s_gen(x,param0);  % initial

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
param.s_minusInf1 = param1(3);
param.s_plusInf1 = param1(4);
param.center1 = param1(5);
param.steepness1 = param1(6);
param.n1 = param0(7);

end