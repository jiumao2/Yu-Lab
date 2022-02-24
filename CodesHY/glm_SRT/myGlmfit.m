function glm_output = myGlmfit(Kernels,num)
    glm_output = zeros(Kernels.n_folds,1);
    group_idx = cell2mat(Kernels.group_idx);
    for k = 1:Kernels.n_folds
        all_ind = [];
        for i = 1:length(num)
            all_ind = [all_ind,Kernels.pos{num(i)}];
        end
        
        test_idx = group_idx(k,:);
        group_idx_copy = group_idx;
        group_idx_copy(k,:) = [];
        train_idx = group_idx_copy(:);
        train_x = Kernels.training_set_x(train_idx,all_ind);
        train_y = Kernels.training_set_y(train_idx,:);
        test_x = Kernels.training_set_x(test_idx,all_ind);
        test_y = Kernels.training_set_y(test_idx,:);
        
        train_x = [ones(size(train_y,1),1),train_x];
        test_x = [ones(size(test_y,1),1),test_x];
        w = glmfit(train_x,train_y,'poisson','constant','off');
        neglogli = neglogli_poissGLM(w,test_x,test_y,1);
        glm_output(k) = neglogli;
    end
end