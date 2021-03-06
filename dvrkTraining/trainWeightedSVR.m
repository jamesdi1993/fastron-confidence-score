function [mdl] = trainWeightedSVR(X_train, y_train, X_test, y_test, tune_param, ...
                                  observation_weights, box_constraint, kernel_scale, epsilon)
    % Train Weighted Version of SVR
    %
    % Input:
    %    X_train - training dataset
    %    y_train - training labels
    %    X_test  - test dataset
    %    y_test  - test labels
    %    tune_param - whether to tune the parameter of SVR
    %    observation weights - weights for each training sample
    %    box_constraint      - box constraint for SVR model, only used if
    %    tune_param is false
    %    kernel_scale        - kernel scale for SVR, only used when
    %    tune_param is false
    %    epsilon             - epsilon for SVR, only used when tune_param
    %    is false
    
    if tune_param
        mdl = fitrsvm(X_train, y_train, 'KernelFunction','rbf', ...
          'Weights', observation_weights, ...
          'OptimizeHyperparameters','auto',...
          'HyperparameterOptimizationOptions',struct('AcquisitionFunctionName',...
          'expected-improvement-plus', ...
          'MaxObjectiveEvaluations', 50 ...
          ));
    else
        mdl = fitrsvm(X_train,y_train,'KernelFunction','rbf','KernelScale', kernel_scale, ...
           'BoxConstraint', box_constraint, ...
           'Epsilon', epsilon, ...
           'Weights', observation_weights ...
           );
    end
    % 
    y_pred_train = predict(mdl, X_train);
    y_pred_test = predict(mdl, X_test);
    
    % MSE Loss;
    eps_train = y_pred_train - y_train;
    l_train = eps_train' * eps_train / size(X_train, 1);
    
    [~, max_train_ind] = max(y_train);
    [~, max_test_ind] = max(y_test); 

    eps_test = y_pred_test - y_test;
    l_test = eps_test' * eps_test / size(X_test, 1);
    fprintf("MSE Loss: %.4f (training); %.4f (test)\n", l_train, l_test);
    fprintf("Maximum loss: %.4f (training); %.4f (test)\n", max(abs(eps_train)), max(abs(eps_test)));
    fprintf("Loss at the maximum score: %.4f (training); %.4f (test)\n", abs(eps_train(max_train_ind)), abs(eps_test(max_test_ind))); 
end