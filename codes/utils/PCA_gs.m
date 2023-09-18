function [g_new,s_new,PCA_param] = PCA_gs(G,S)

x = (G);
y = (S);
mx = mean(x);
my = mean(y);
 
vect_pca = [x'-mx,y'-my];
[coeff,~] = pca(vect_pca); 

th = pi/4;
rotM = [sin(th) cos(th); -cos(th) sin(th)];

gs_new = (rotM*(vect_pca*coeff)'); % PCA coordinates 
PCA_param = struct;
PCA_param.rotM = rotM;
PCA_param.mx = mx;
PCA_param.my = my;
PCA_param.coeff = coeff;
PCA_param.function = 'PCA_param.rotM*([x-PCA_param.mx,y-PCA_param.my]*PCA_param.coeff)';
g_new = gs_new(1,:);
s_new = gs_new(2,:);

end