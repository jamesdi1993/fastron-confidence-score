clear; close all;
rng(0);
init;

%% load collision_score data
% score_dict = load("/Users/jamesdi/Dropbox/UCSD/Research/ARCLab/Code/"...
%  + "ConfidenceScore/constraint_log/collision_score.mat");
score_dict = load('/home/nikhildas/workspace/fastron_experimental/fastron_vrep/constraint_analysis/log/collision_score_n1125.mat');
score = getfield(score_dict, 'collision_score');
X = score(:, 1:4);
y = score(:, 5);
n = size(X, 1);
input_type = "Score from 0 to 1";
spec = "%2f";

training_p = 0.8;
validation_p = 0.1;
test_p = 0.1;

% train, validation and test splits;
X_train = X(1:training_p * n, :);
y_train = y(1:training_p * n, :);
X_holdout = X(training_p*n+1:(validation_p + training_p)*n, :);
y_holdout = y(training_p*n+1:(validation_p + training_p)*n, :);
X_test = X((validation_p + training_p)*n+1:n, :);
y_test = y((validation_p + training_p)*n+1:n, :);

%% MLP for regression;
tic();
h = [256,256];            % two hidden layers with 10 and 6 neurons
lambda = 0.0001; 
[model, llh] = mlpRegSigmoid(X_train',y_train',h,lambda);
p_mlp = mlpRegPredSigmoid(model,X_test')';
% p_mlp_clipped = max(0, min(1, p_mlp)); % clip the values between [0,1];

t_mlp = toc();
fprintf("Finished training for MLP");

%% MLP for classification;
% tic()
% h = [256, 256]; % Two 256 layer MLP; 
% lambda = 0.0001; %  regularization term;
% y_train_mlp = (y_train + 3) / 2; % convert (-1,1) into (1,2);
% [model, llh] = mlpClass(X_train',y_train_mlp',h,lambda); % default is using sigmoid function;
% t_mlp_train = toc();
% 
% tic();
% [y_pred_mlp, p_mlp] = mlpClassPred(model,X_test');
% y_pred_mlp = (y_pred_mlp * 2 - 3)'; % convert back into (-1, 1);
% p_mlp = p_mlp(2, :)'; % get the probability of inCollision;
% t_mlp_test = toc();

%% IVM
lambda = 5;
useUnbiasedVersion = false;
g = 20;

tic();
K = rbf(X_train, X_train, g);
if useUnbiasedVersion
    [a_ivm, S, idx] = ivmTrain(X_train, y_train, K, lambda);
else
    [a_ivm, S, idx] = ivmTrain2(X_train, y_train, K, lambda);
end
t_ivm_train = toc();

tic();
if useUnbiasedVersion
    F_test_IVM = rbf(X_test, S, g)*a_ivm;
else
    F_test_IVM = rbf(X_test, S, g)*a_ivm(1:end-1) + a_ivm(end);
end
p_ivm = 1./(1 + exp(-F_test_IVM));
fprintf("Finished training for IVM");

%% GP
Kn = rbf(X_train, X_test, g);
Kv = rbf(X_test, X_test, g);
[mu, cov] = gp(K, Kn, Kv, y_train, 0);
p_gp = (mu - min(mu))/(max(mu) - min(mu)); % convert it to a [0, 1] value;

%% GP - Matlab;
gprMdl = fitrgp(X_train, y_train, 'KernelFunction', 'squaredexponential', ...
    'Sigma', sqrt(1.0/(2*g)));
p_gp2 = min(max(predict(gprMdl, X_test),0), 1);
% p_gp2 = (p_gp2 - min(p_gp2))/(max(p_gp2) - min(p_gp2));

%% Bar graph for scores;
scoreFuns = {@nll, @brierScore};
p = [p_mlp(:) p_ivm(:) p_gp(:) p_gp2(:)];
score = zeros(size(p,2),2);

figure_title = "%s input for %d samples";
figure('NumberTitle', 'off', 'Name', sprintf(figure_title, input_type, size(X_train,1)));
for i=1:size(p,2)
    for j=1:size(scoreFuns,2)
        scoreFun = scoreFuns{j};
        score(i,j) = scoreFun(p(:, i),y_test);
    end
end

subplot(1,1,1);
h1 = bar(score);
set(gca,'xticklabel', ["MLP" "IVM" "GP" "GP Matlab"]); 
l1 = cell(1,2);
l1{1}='Negative Log Loss'; l1{2}='Brier Score';
legend(h1,l1);
title("Confidence Loss");