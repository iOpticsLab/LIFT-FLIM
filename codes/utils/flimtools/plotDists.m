function [] = plotDists(X,ID,CM,tit)
if(max(ID)>size(CM,1)),disp('Not neough colors! Repeating some');CM=repmat(CM,[22,1]);end
hold on;ms=4;
        for ii=1:size(X,1)
%            h=plot(X(ii,1),X(ii,2),'.k','markersize',ms+1);
            h=plot(X(ii,1),X(ii,2),'o','markersize',ms,'MarkerFaceColor',CM(ID(ii),:), 'MarkerEdgeColor',.68*CM(ID(ii),:));            
%             set(h,'color',CM(ID(ii),:));            
        end
        if((~isempty(tit))||(nargin<4));title(tit);end
        set(gcf,'color','w');
ax=gca;
set(ax,'fontname','calibri','fontsize',14,'XMinorGrid','on','YMinorGrid','on','ZMinorGrid','on','box','on');
set(ax.YLabel,'rotation',0,'FontWeight','normal');
set(ax.XLabel,'FontWeight','normal');
grid on;set(gca,'xticklabel',[],'yticklabel',[]);
axis equal;
xl=xlim();yl=ylim();
fac=.18;
phasorPlotPoints(-[100,100]);
xlim([xl(1)-diff(xl)*fac xl(2)+diff(xl)*fac]);ylim([yl(1)-diff(yl)*fac yl(2)+diff(yl)*fac]);
     drawnow;  grid on;set(gca,'XMinorGrid','on','YMinorGrid','on'); 
end