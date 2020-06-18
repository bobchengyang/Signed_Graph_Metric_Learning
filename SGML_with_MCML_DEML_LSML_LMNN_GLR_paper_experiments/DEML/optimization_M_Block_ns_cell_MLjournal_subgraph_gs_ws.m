function [M,...
    scaled_M,...
    scaled_factors,...
    M_current_eigenvector,...
    min_objective,...
    bins,...
    num_list,...
    LP_A_sparse_i,...
    LP_A_sparse_j,...
    LP_A_sparse_s,...
    LP_b,...
    LP_lb,...
    LP_ub,...
    LP_Aeq,...
    LP_beq,...
    zero_mask,...
    scaler_v,...
    remaining_idx,...
    lu_bound_idx,...
    options] = optimization_M_Block_ns_cell_MLjournal_subgraph_gs_ws(current_node,league_vec,league_vec_temp,flip_number,...
    scaled_factors_h,...
    Ms_off_diagonal,...
    feature_N,...
    G,...
    M,...
    BCD,...
    remaining_idx,...
    M_current_eigenvector,...
    rho,...
    S_upper,...
    scaled_M,...
    scaled_factors,...
    bins,...
    objective_previous,...
    tol_golden_search,...
    nv,...
    zz,...
    num_list,...
    D,...
    options,...
    LP_A_sparse_i,...
    LP_A_sparse_j,...
    LP_A_sparse_s,...
    LP_b,...
    LP_lb,...
    LP_ub,...
    dia_idx,...
    tol_NR,...
    tol_GD,...
    length_D,...
    GS_or_NR,...
    max_iter)

tol_offdia=Inf;

counter=0;

M_temp_best=M;

objective_previous_temp=objective_previous;

ddd = (0 - rho - (sum(abs(Ms_off_diagonal),2)-diag(abs(Ms_off_diagonal))));

sign_vecdd = flip_number'*current_node*-1;

LP_A_sparse_s(1:feature_N-1)=sign_vecdd.*abs(scaled_factors_h);

LP_A_sparse_j(feature_N)=feature_N-1+BCD;

scaler_v = abs(scaled_factors(remaining_idx,BCD));

for LP_A_i=1:feature_N-1
    temp_index=feature_N+(LP_A_i-1)*2+1;
    temp_index1=feature_N+(LP_A_i-1)*2+2;
    LP_A_sparse_s(temp_index)=sign_vecdd(1,LP_A_i)*scaler_v(LP_A_i);
    LP_A_sparse_j(temp_index1)=feature_N-1+remaining_idx(LP_A_i);
    LP_b(LP_A_i+1)=ddd(LP_A_i);
end

LP_A = sparse(LP_A_sparse_i,LP_A_sparse_j,LP_A_sparse_s,1+feature_N,feature_N-1+feature_N);

LP_lb(sign_vecdd==-1)=-Inf;
LP_ub(sign_vecdd==-1)=0;
LP_lb(sign_vecdd==1)=0;
LP_ub(sign_vecdd==1)=Inf;

zero_mask=ones(2*feature_N-1,1);
lu_bound_idx=scaler_v==0;
LP_lb(lu_bound_idx)=0;
LP_ub(lu_bound_idx)=0;
zero_mask(lu_bound_idx)=0;

LP_Aeq = [];
LP_beq = [];

%% LP settings that do not have to be set in every Frank-Wolfe iteration ends
while tol_offdia>1e-3
 
    s_k = linprog(G,...
        LP_A,LP_b,...
        LP_Aeq,LP_beq,...
        LP_lb,LP_ub,options);

    while isempty(s_k) == 1
        disp('===trying with larger OptimalityTolerance===');
        options.OptimalityTolerance = options.OptimalityTolerance*10;
        s_k = linprog(G,...
            LP_A,LP_b,...
            LP_Aeq,LP_beq,...
            LP_lb,LP_ub,options);
    end
    %% set a step size
    if isequal(league_vec,league_vec_temp)==1

        M_previous=[M_temp_best(remaining_idx,BCD);diag(M_temp_best)];
        t_M21_solution_previous=s_k - M_previous;
    
        if GS_or_NR==1
            %% GS starts
            [gamma] = optimization_M_golden_section_search(...
                0,...
                1,...
                M_previous,...
                t_M21_solution_previous,...
                M_temp_best,...
                feature_N,...
                BCD,...
                tol_golden_search,...
                zero_mask,...
                0,...
                0,...
                remaining_idx,...
                D,...
                dia_idx);
            if counter==0 && gamma==0
                min_objective=objective_previous_temp;
                return
            end
            %% GS ends
        else
            %% NR starts
            [gamma] = optimization_M_NR(...
                M_previous,...
                t_M21_solution_previous,...
                zero_mask,...
                remaining_idx,...
                BCD,...
                feature_N,...
                M_temp_best,...
                zz,...
                nv,...
                D,...
                counter,...
                dia_idx,...
                tol_NR,...
                tol_GD,...
                length_D);
            if counter==0 && gamma==0
                min_objective=objective_previous_temp;
                return
            end
            %% NR ends
        end
        t_M21 = M_previous + gamma * t_M21_solution_previous;
        t_M21 = t_M21.*zero_mask;
        
        M_updated=M_temp_best;
        M_updated(BCD,remaining_idx)=t_M21(1:feature_N-1);
        M_updated(remaining_idx,BCD)=M_updated(BCD,remaining_idx);
        %M_updated(logical(eye(feature_N)))=t_M21(feature_N-1+1:end);
        M_updated(dia_idx)=t_M21(feature_N-1+1:end);
    else
        M21_updated = s_k.*zero_mask;
        
        M_updated = M_temp_best;
        M_updated(remaining_idx,BCD)=M21_updated(1:feature_N-1);
        M_updated(BCD,remaining_idx)=M_updated(remaining_idx,BCD);
        %M_updated(logical(eye(feature_N)))=M21_updated(feature_N-1+1:end);
        M_updated(dia_idx)=M21_updated(feature_N-1+1:end);
        min_objective = dml_obj(M_updated,D);
        
        %% reject the result (reject the color change) if it is larger than previous
        if min_objective<=objective_previous_temp
            min_objective=objective_previous_temp;
            %disp('color update return');
            return
            %% there is no need to iterate, since the node color is changed
        else
            M_temp_best = M_updated;
            %disp('color update break');
            break % no need to iterate, not even once, otherwise it is wrong.
        end
    end
    
    %% evaluate the objective value
    min_objective = dml_obj(M_updated,D);
    if min_objective<=objective_previous_temp
        if counter>0
            min_objective=objective_previous_temp;
            break
        else
            min_objective=objective_previous_temp;
            %disp('early stop');
            return
        end
    end
    
    M_temp_best = M_updated;
    
    %% choose the M_temp_best that has not been thresholded to compute the gradient
    [ G ] = dml_gradient(...
        M_temp_best, ...
        D, ...
        feature_N, ...
        nv, ...
        BCD, ...
        remaining_idx,...
        length_D);
    
    G=-G;
 
    tol_offdia=norm(min_objective-objective_previous_temp);
    
    objective_previous_temp=min_objective;
    
    counter=counter+1;
    if counter==max_iter
        break
    end
    
end

M_temp_best(abs(M_temp_best)<1e-5)=0;

%% detect subgraphs
bins_temp=bins;
M_current_eigenvector0=M_current_eigenvector;
num_list0=num_list;
if sum(abs(M_temp_best(BCD,remaining_idx)))==0 % disconnected
    if feature_N==max(bins_temp) % already disconnected   
    else
    bins_temp(BCD)=max(bins_temp)+1; % assign a subgraph number
    M_current_eigenvector0(num_list0==BCD)=[]; % heuristicaly remove the 1st entry of M_current_eigenvector as the lobpcg warm start
    num_list0(num_list0==BCD)=[];
    M_current_eigenvector0=M_current_eigenvector0/sqrt(sum(M_current_eigenvector0.^2));
    end
end
%% evaluate the temporarily accepted result with temporary scaled_M and scaled_factors

[M_current_eigenvector0,scaled_M_,scaled_factors_] = optimization_M_scalars(M_temp_best,feature_N,1,M_current_eigenvector0,bins_temp);

lower_bounds = sum(abs(scaled_M_),2)-abs(scaled_M_(dia_idx))+rho;

%% reject the result if the lower_bounds are larger than S_upper
if sum(lower_bounds) > S_upper
    min_objective=objective_previous;
    %disp(['lower bounds sum:' num2str(sum(lower_bounds))]);
    %disp('========lower bounds sum larger than S_upper!!!========');
    return
end

%% M_temp_best passes all tests, now update the results
bins=bins_temp;
M=M_temp_best;
scaled_M=scaled_M_;
scaled_factors=scaled_factors_;
M_current_eigenvector=M_current_eigenvector0;
num_list=num_list0;
end

