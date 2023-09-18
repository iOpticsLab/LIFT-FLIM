function [] = niceplot()
set(gcf,'color','w');
ax=gca;
set(ax,'fontname','verdana','fontsize',14,'XMinorGrid','on','YMinorGrid','on','ZMinorGrid','on','box','on');
set(ax.YLabel,'rotation',0,'FontWeight','normal');
set(ax.XLabel,'FontWeight','normal');
grid on;



end