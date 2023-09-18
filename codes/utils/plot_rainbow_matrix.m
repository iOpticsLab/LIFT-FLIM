function plot_rainbow_matrix(x,y,linemarker)

if nargin<3
    linemarker = '-';
if nargin == 2&&ischar(y)
    linemarker = y;
    y = x;
    x = meshgrid(1:size(y,1),ones(1,size(y,2)))';    
end
if nargin == 1
    y = x;
    x = meshgrid(1:size(y,1),ones(1,size(y,2)))';
end
end
if size(x,2) == 1
    x = repmat(x,1,size(y,2));
end
    figure(gcf)
    hold on
    L = size(x,2);
    co = jet(L);
    for i = 1:L
        plot(x(:,i),y(:,i),linemarker,'Color',co(i,:))
    end
end
