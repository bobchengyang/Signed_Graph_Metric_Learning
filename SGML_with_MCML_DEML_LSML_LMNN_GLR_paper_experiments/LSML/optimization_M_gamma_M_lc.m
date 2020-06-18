function [G1] = optimization_M_gamma_M_lc(...
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
    S,...
    D,...
    dia_idx)

t_M21 = M_previous + gamma * t_M21_solution_previous;
t_M21=t_M21.*zero_mask;

if nv==feature_N+(feature_N*(feature_N-1)/2) && BCD==0
    total_offdia=feature_N*(feature_N-1)/2;
    M_lc(zz)=t_M21(1:total_offdia);
    M_lc_t=M_lc';
    M_lc(zz')=M_lc_t(zz');
    %M_lc(logical(eye(feature_N)))=t_M21(total_offdia+1:end);
    M_lc(dia_idx)=t_M21(total_offdia+1:end);
elseif nv==2*feature_N-1
    M_lc(remaining_idx,BCD)=t_M21(1:feature_N-1);
    M_lc(BCD,remaining_idx)=M_lc(remaining_idx,BCD);
    %M_lc(logical(eye(feature_N)))=t_M21(feature_N-1+1:end);
    M_lc(dia_idx)=t_M21(feature_N-1+1:end);
end

[ G1 ] = optimization_M_set_step_gradient(S, D, feature_N, M_lc, nv, zz, BCD, remaining_idx, t_M21_solution_previous.*zero_mask);
G1=sum(G1(:));
end

