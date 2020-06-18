function [ class_result, ...
    error_matrix,...
    weights_result, ...
    GT_obj, ...
    final_obj, ...
    error_result,obj_vec,time_vec] = ...
    optimization_M_one_against_one_binary_R_Block_CD( fold_i, ...
    feature, ...
    class, ...
    train, ...
    test, ...
    class_i, ...
    class_j, ...
    order_number, ...
    class_result, ...
    error_matrix,...
    weights_result, ...
    GT_obj, ...
    final_obj, ...
    error_result,...
    S_upper,...
    rho,...
    epsilon,...
    proportion_factor,...
    proportion_threshold,...
    tol_set_prepro,...
    tol_main,...
    tol_diagonal,...
    tol_offdiagonal,...
    step_scale,...
    step_scale_od)
%ONE_AGAINST_ONE_BINARY Summary of this function goes here
%   Detailed explanation goes here

class(class~=class_i) = class_j; % turn ground truth labels to a binary one

flag = 0;

while flag < 1
    
    train_index = train;
    test_index = test;
    
    feature_train = feature(train_index,:);
  
    %feature_train = optimization_M_scaledata(feature_train,0,2);  

%     feature_train_l2=sqrt(sum(feature_train.^2,2));
%     for i=1:size(feature_train,1)
%         feature_train(i,:)=feature_train(i,:)/feature_train_l2(i);
%     end  
    
    mean_TRAIN_set_0 = mean(feature_train);
    std_TRAIN_set_0 = std(feature_train);
    
    mean_TRAIN_set = repmat(mean_TRAIN_set_0,size(feature_train,1),1);
    std_TRAIN_set = repmat(std_TRAIN_set_0,size(feature_train,1),1);
    
    feature_train = (feature_train - mean_TRAIN_set)./std_TRAIN_set;
    
    if length(find(isnan(feature_train)))>0
        error('features have NaN(s)');
    end
    
    feature_train_l2=sqrt(sum(feature_train.^2,2));
    for i=1:size(feature_train,1)
        feature_train(i,:)=feature_train(i,:)/feature_train_l2(i);
    end       
    
    feature_test = feature(test_index,:);
    
    %feature_test = optimization_M_scaledata(feature_test,0,2);
    
    % mean_TRAIN_set_0 = mean(feature_test);
    % std_TRAIN_set_0 = std(feature_test);
    
    mean_TEST_set = repmat(mean_TRAIN_set_0,size(feature_test,1),1);
    std_TEST_set = repmat(std_TRAIN_set_0,size(feature_test,1),1);
    
    feature_test = (feature_test - mean_TEST_set)./std_TEST_set;
    
    feature_test_l2=sqrt(sum(feature_test.^2,2));
    for i=1:size(feature_test,1)
        feature_test(i,:)=feature_test(i,:)/feature_test_l2(i);
    end      
    
    feature_REFORM = feature;
    
    feature_REFORM(train_index,:) = feature_train;
    feature_REFORM(test_index,:) = feature_test;
    feature_REFORM(~(train_index|test_index),:) = [];
    
    class_test = class(test_index);
    
    %% SDP
    
    feature_train_test = feature_REFORM;
    
    class_train_test = class(train_index|test_index);
    class_train_test(class_train_test==class_i) = 1;
    class_train_test(class_train_test==class_j) = -1;
    
    initial_label = zeros(size(class,1),1);
    initial_label(train_index&class==class_i) = 1;
    initial_label(train_index&class==class_j) = -1;
    initial_label(~train_index&~test_index) = [];
    initial_label_index = initial_label ~= 0;
    
    if flag == 0
        [~,class_result_temp,...
            GT_obj_all, obj_all, error_iter,obj_vec,time_vec] = ...
            optimization_M_classification_main_workflow_wei_partial( class_test, ...
            feature_train_test, ...
            initial_label, ...
            initial_label_index, ...
            class_train_test, ...
            class_i, ...
            class_j, ...
            S_upper,...
            rho,...
            epsilon,...
            proportion_factor,...
            proportion_threshold,...
            tol_set_prepro,...
            tol_main,...
            tol_diagonal,...
            tol_offdiagonal,...
            step_scale,...
            step_scale_od);

%         [~,class_result_temp,...
%             GT_obj_all, obj_all, error_iter,obj_vec,time_vec] = ...
%             optimization_M_MLjournal_subgraph_1sbb2f_time( class_test, ...
%             feature_train_test, ...
%             initial_label, ...
%             initial_label_index, ...
%             class_train_test, ...
%             class_i, ...
%             class_j, ...
%             S_upper,...
%             rho,...
%             epsilon,...
%             proportion_factor,...
%             proportion_threshold,...
%             tol_set_prepro,...
%             tol_main,...
%             tol_diagonal,...
%             tol_offdiagonal);
%         
    else
        [~,class_result_temp,...
            GT_obj_all, obj_all, error_iter] = ...
            optimization_M_classification_main_workflow_ellipse_partial( class_test, ...
            feature_train_test, ...
            initial_label, ...
            initial_label_index, ...
            class_train_test, ...
            class_i, ...
            class_j, ...
            S_upper,...
            rho,...
            epsilon,...
            proportion_factor,...
            proportion_threshold,...
            tol_set_prepro,...
            tol_main,...
            tol_diagonal,...
            tol_offdiagonal,...
            step_scale,...
            step_scale_od,...
            1e-4);
    end
    
    %feature(:, check_correlation > 0 ) = feature(:, check_correlation > 0 ); % flip the sign of anti-correlated features
    
    flag = flag + 1;
end

weights_result{fold_i,order_number} = 0;
GT_obj{fold_i,order_number} = GT_obj_all;
final_obj{fold_i,order_number} = obj_all;
error_result{fold_i,order_number} = error_iter;

%% SVM and SDP binary results
[ class_result, ...
    error_matrix] = ...
    optimization_M_one_against_one_binary_results( fold_i, ...
    order_number, ...
    class_test, ...
    test_index,...
    class_result, ...
    class_result_temp, ...
    error_matrix);
end

