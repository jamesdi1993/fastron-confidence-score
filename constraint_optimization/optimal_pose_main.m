close all; clear
rng(0);
init;

input_path = base_dir + "log/%s_n%d.mat";
output_path = base_dir + "pose/poses_%s.csv";

dataset = 'reachability_score';
n = 2925;
[X_train, y_train, X_test, y_test] = load_dvrk(input_path, dataset, n, false);
[max_ytrain, max_idx_train] = max(y_train);
[max_ytest, max_idx_test] = max(y_test);
fprintf("The maximum of y_train is: %.2f; position: [%.3f, %.3f, %.3f]\n", max_ytrain, X_train(max_idx_train, :));
fprintf("The maximum of y_test is: %.2f; position: [%.3f, %.3f, %.3f]\n", max_ytest, X_train(max_idx_test, :));

% self_collision_mdl = trainModel(X_train, y_train, X_test, y_test, 'svr');
reachability_mdl = trainModel(X_train, y_train, X_test, y_test, 'svr');

ub = max([X_train; X_test], [], 1); % upper bound of each column;
lb = min([X_train; X_test], [], 1); % lower bound

% x0 = [-1.233, -0.703, 0.6599, -1.459];
x0 = [-0.983, -0.253, 0.6599,-1.209];
z = x0(3);

x0 = x0([1 2 4]);
x = find_pose(x0, lb, ub, reachability_mdl);
% x = find_pose(x0, lb, ub, self_collision_mdl);

reachability_score = predict(reachability_mdl, x0);
% self_collision_score = predict(self_collision_mdl, x);
fprintf("Position: [%.3f, %.3f, %.3f]; Reachability score is: %s\n", x0, reachability_score);
% fprintf("Position: [%.3f, %.3f, %.3f]; Predicted self-collision score: %s; Actual: %s\n", x, self_collision_score);

path = sprintf(output_path, '11_19');
X = [x(1:2), z, x(3)];
writematrix(X, path);
% TODO: output it to a csv file for validation on the dVRK scene;