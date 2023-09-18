function [G_unmix0,S_unmix0,S,L,U_tau,U_lambda,Param] = Phasor_SFLIM_Unmixing2(TRES,G_tau,S_tau,n_comp,Ch_vect,Ch_vect_spectra,Display,param0)

if nargin<8, param0 = struct; end
if nargin<7, Display = 0; end
if nargin<6, Ch_vect_spectra = Ch_vect; end
if nargin<5, Ch_vect = 1:length(G_tau); end

th = pi/4;
rotM = [sin(th) cos(th); -cos(th) sin(th)];
[g_new,s_new,PCA_param] = PCA_gs(G_tau(Ch_vect),S_tau(Ch_vect));  % generate new pca coordinates
if n_comp == 2
    % Define starting parameters
    if nargin>=7
    if isfield(param0,'g_plusInf1')
        tmp = PCA_param.rotM*([param0.g_plusInf1-PCA_param.mx,param0.s_plusInf1-PCA_param.my]*PCA_param.coeff)'; 
        param0.g_plusInf1 = tmp(1);
        param0.s_plusInf1 = tmp(2);
    else
        param0.g_plusInf1 = g_new(end);
        param0.s_plusInf1 = s_new(end);
    end
    if isfield(param0,'g_minusInf1') 
        tmp = PCA_param.rotM*([param0.g_minusInf1-PCA_param.mx,param0.s_minusInf1-PCA_param.my]*PCA_param.coeff)'; 
        param0.g_minusInf1 = tmp(1);
        param0.s_minusInf1 = tmp(2);
    else
        param0.g_minusInf1 = g_new(1);
        param0.s_minusInf1 = s_new(1);
    end
    if isfield(param0,'center1')==0, param0.center1      = (round(length(g_new)/3)); end
    if isfield(param0,'steepness1')==0, param0.steepness1   = 2; end
    if isfield(param0,'n1')==0, param0.n1           = 0.5; end

        Param = fit_GenLogistic_GS(1:length(Ch_vect),g_new,s_new,0,param0);
    else
        Param = fit_GenLogistic_GS(1:length(Ch_vect),g_new,s_new,0);
    end
    gs_unmixed_new = [Param.g_minusInf1 Param.g_plusInf1;Param.s_minusInf1 Param.s_plusInf1];
end

if n_comp == 3
    if nargin>=7
    % Define starting parameters
    if isfield(param0,'g_minusInf1') 
        tmp = PCA_param.rotM*([param0.g_minusInf1-PCA_param.mx,param0.s_minusInf1-PCA_param.my]*PCA_param.coeff)'; 
        param0.g_minusInf1 = tmp(1);
        param0.s_minusInf1 = tmp(2);
    else
        param0.g_minusInf1 = g_new(1);
        param0.s_minusInf1 = s_new(1);
    end
    if isfield(param0,'g_plusInf1')
        tmp = PCA_param.rotM*([param0.g_plusInf1-PCA_param.mx,param0.s_plusInf1-PCA_param.my]*PCA_param.coeff)'; 
        param0.g_plusInf1 = tmp(1);
        param0.s_plusInf1 = tmp(2);
    else
        param0.g_plusInf1 = g_new(round(length(g_new)/2));
        param0.s_plusInf1 = s_new(round(length(g_new)/2));
    end
    if isfield(param0,'g_plusInf2')
        tmp = PCA_param.rotM*([param0.g_plusInf2-PCA_param.mx,param0.s_plusInf2-PCA_param.my]*PCA_param.coeff)'; 
        param0.g_plusInf2 = tmp(1);
        param0.s_plusInf2 = tmp(2);
    else
        param0.g_plusInf2 = g_new(end);
        param0.s_plusInf2 = s_new(end);
    end
    if isfield(param0,'center1')==0, param0.center1      = (round(length(g_new)/3)); end
    if isfield(param0,'steepness1')==0, param0.steepness1   = 1/length(g_new)*30; end
    if isfield(param0,'n1')==0, param0.n1           = 1; end
    if isfield(param0,'center2')==0, param0.center2      = (round(length(g_new)/3*2)); end
    if isfield(param0,'steepness2')==0, param0.steepness2   = 1/length(g_new)*30; end
    if isfield(param0,'n2')==0, param0.n2           = 1; end
%         Param = fit_DoubleGenLogistic_GS_fx(1:length(Ch_vect),g_new,s_new,0,param0);
        Param = fit_DoubleGenLogistic_GS_fx(1:length(Ch_vect),g_new,s_new,Display,param0);
    else
%         Param = fit_DoubleGenLogistic_GS_fx(1:length(Ch_vect),g_new,s_new,0);
         Param = fit_DoubleGenLogistic_GS_fx(1:length(Ch_vect),g_new,s_new,Display);
    end
    gs_unmixed_new = [Param.g_minusInf1 Param.g_plusInf1 Param.g_plusInf2;Param.s_minusInf1 Param.s_plusInf1 Param.s_plusInf2];
end
gs_unmix = ((inv(rotM)*gs_unmixed_new)')*inv(PCA_param.coeff);
G_unmix0 = gs_unmix(:,1)+mean(G_tau(Ch_vect));
S_unmix0 = gs_unmix(:,2)+mean(S_tau(Ch_vect));

if n_comp == 2
[U1_tau,U2_tau] = Phasor_Unmixing2comp_distance(G_tau(Ch_vect_spectra)+1i*S_tau(Ch_vect_spectra),G_unmix0+1i*S_unmix0);
U_tau = cat(1,U1_tau,U2_tau);
else
[U1_tau,U2_tau,U3_tau] = Phasor_Unmixing3comp_distance(G_tau(Ch_vect_spectra)+1i*S_tau(Ch_vect_spectra),G_unmix0+1i*S_unmix0);
%[U1_tau,U2_tau,U3_tau] = Phasor_Unmixing3comp(G_tau+1i*S_tau,G_unmix0(1)+1i*S_unmix0(1),G_unmix0(2)+1i*S_unmix0(2),G_unmix0(3)+1i*S_unmix0(3));
U_tau = cat(1,U1_tau,U2_tau,U3_tau);
U_tau(U_tau<0) = 0;
U_tau(U_tau>1) = 1;
U_tau = U_tau./repmat(sum(U_tau,1),size(U_tau,1),1); % output amplitude
end

S = zeros(size(U_tau)); % spectrum unmixing amplitude
for i = 1:n_comp
    S(i,:) = sum(TRES(:,Ch_vect_spectra),1).*U_tau(i,:);
end  % output unmixed spectrum
[G_lambda,S_lambda] = PhasorTransform(TRES(:,Ch_vect_spectra),2);
[G_lambda_pure,S_lambda_pure] = PhasorTransform(S,2); % purified transform
if n_comp == 2
    [U1_lambda,U2_lambda] = Phasor_Unmixing2comp_distance(G_lambda'+1i*S_lambda',G_lambda_pure+1i*S_lambda_pure);
    U_lambda = cat(2,U1_lambda',U2_lambda');
else
    [U1_lambda,U2_lambda,U3_lambda] = Phasor_Unmixing3comp_distance(G_lambda'+1i*S_lambda',G_lambda_pure+1i*S_lambda_pure);
    U_lambda = cat(2,U1_lambda',U2_lambda',U3_lambda');
end
L = zeros(size(U_lambda)); % lifetime unmixing amplitude
for i = 1:n_comp
    L(:,i) = sum(TRES(:,Ch_vect_spectra),2).*U_lambda(:,i);
end  % output lifetime decay


if Display == 1
    figure
    subplot(2,2,2)
    plot_rainbow(G_tau(Ch_vect),S_tau(Ch_vect),'-o')
    hold on
    plot(G_unmix0,S_unmix0,'-*k')
    plot_PhasorCircle
    xlim([0 1])
    xlim([0 1])
    Figure_Format_Graph

    subplot(2,2,3)
    plot(S')
    Figure_Format_Graph
    ylim([0 Inf])

    subplot(2,2,4)
    plot(L)
    set(gca,'yscale','log');
    Figure_Format_Graph

    subplot(2,2,1)
    imagesc(real(log(TRES)))
    Figure_Format_Graph
end
end