function [xunit, yunit] = plot_SpectrumPhasorCircle()

hold on
th = 0:pi/50:2*pi;
xunit = 1.0 * cos(th) ;
yunit = 1.0 * sin(th);
plot(xunit, yunit,':k');
end