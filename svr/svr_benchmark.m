
function [t_train, t_test, l, Sn] = svr_benchmark(dataset, n)

    %% Load collision_score data
    score_dict = load(sprintf('/home/jamesdi1993/workspace/arclab/fastron_experimental/fastron_vrep/constraint_analysis/log/%s_n%d.mat', dataset, n));
    score = getfield(score_dict, dataset);
    X = score(:, [1 2 4]); % omit z because it is held constant in our dataset; [x,y,\theta]
    y = score(:, 5);
    n = size(X, 1);
    input_type = "Score from 0 to 1";

    p_train = 0.8;
    idx = randperm(n); % shuffle the dataset;
    X = X(idx, :);
    X_train = X(1:ceil(n*p_train), :);
    y_train = y(1:ceil(n*p_train));

    X_test = X(ceil(n*p_train+1):n, :);
    y_test = y(ceil(n*p_train+1):n);

    fprintf("Size of training set: %d; test set: %d", size(X_train,1), size(X_test,1));

    %% Fit Support Vector Regression on the data;
    tic()
    svrMdl = fitrsvm(X_train, y_train,'KernelFunction','rbf', 'KernelScale','auto',...
                'Solver','SMO', 'Epsilon', 0.2, ...
                'Standardize',false, 'verbose',0);
    t_train = toc();
    
    Sn = size(svrMdl.SupportVectors, 1);
    fprintf("Number of support points: %d\nNumber of iterations:%d\n", Sn, svrMdl.NumIterations);


    % Compute MSE Loss;
    n_test = size(X_test, 1);
    tic()
    y_pred = predict(svrMdl, X_test);
    t_test = toc() / n_test;
    mu = max(min(y_pred, 1),0); % clip the value between 0 and 1;
    eps = y_pred - y_test;
    l = eps' * eps / n_test;
    fprintf("MSE Loss: %.4f\n", l);
    fprintf("Training time: %s\nTest time per data point: %s\n", t_train, t_test);
end

