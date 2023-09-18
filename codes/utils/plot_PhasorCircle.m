function plot_PhasorCircle()

hold on
th = 0:pi/50:2*pi;
xunit = 0.5 * cos(th) + 0.5;
yunit = 0.5 * sin(th);
xunit = xunit(yunit>0);
yunit = yunit(yunit>0);
plot(xunit, yunit,':k');
end