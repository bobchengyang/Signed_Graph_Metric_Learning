function [gamma] = optimization_M_gamma_GD(...
    M_previous,...
    t_M21_solution_previous,...
    zero_mask,...
    remaining_idx,...
    BCD,...
    feature_N,...
    M_lc,...
    zz,...
    nv,...
    D,...
    dia_idx,...
    tol_GD,...
    length_D)

% %% examine the gradient at 0 and 1
% [G_0] = optimization_M_gamma_M_lc(...
%     M_previous,...
%     0,...
%     t_M21_solution_previous,...
%     zero_mask,...
%     remaining_idx,...
%     BCD,...
%     feature_N,...
%     partial_feature,...
%     M_lc,...
%     zz,...
%     nv,...
%     S,...
%     D,...
%     partial_sample);
% [G_1] = optimization_M_gamma_M_lc(...
%     M_previous,...
%     1,...
%     t_M21_solution_previous,...
%     zero_mask,...
%     remaining_idx,...
%     BCD,...
%     feature_N,...
%     partial_feature,...
%     M_lc,...
%     zz,...
%     nv,...
%     S,...
%     D,...
%     partial_sample);
% if G_0<=0 && G_1<=0 % fmax=f(gamma=0)
%     gamma=0;
% elseif G_0>=0 && G_1>=0 % fmax=f(gamma=1)
%     gamma=1;
% else % fmax=f(gamma\in[0,1])
    gL=0;
    gU=1;
    nn=0;
    while abs(gL-gU)>tol_GD
        nn=nn+1;
        gamma=(gL+gU)/2;
        [G_gM] = optimization_M_gamma_M_lc(...
            M_previous,...
            gamma,...
            t_M21_solution_previous,...
            zero_mask,...
            remaining_idx,...
            BCD,...
            feature_N,...
            M_lc,...
            zz,...
            nv,...
            D,...
            dia_idx,...
            length_D);
        if G_gM<0 % fmax=f(gamma\in[gL,gamma])
            gU=gamma;
%             gamma=(gL+gU)/2;
%             [G_gM] = optimization_M_gamma_M_lc(...
%                 M_previous,...
%                 gamma,...
%                 t_M21_solution_previous,...
%                 zero_mask,...
%                 remaining_idx,...
%                 BCD,...
%                 feature_N,...
%                 M_lc,...
%                 zz,...
%                 nv,...
%                 D,...
%                 dia_idx,...
%                 length_D);
        elseif G_gM>0 % fmax=f(gamma\in[gamma,gU])
            gL=gamma;
%             gamma=(gL+gU)/2;
%             [G_gM] = optimization_M_gamma_M_lc(...
%                 M_previous,...
%                 gamma,...
%                 t_M21_solution_previous,...
%                 zero_mask,...
%                 remaining_idx,...
%                 BCD,...
%                 feature_N,...
%                 M_lc,...
%                 zz,...
%                 nv,...
%                 D,...
%                 dia_idx,...
%                 length_D);
        else % G_gM=0
            %gamma=gM;
            break
        end
    end
% end

end

