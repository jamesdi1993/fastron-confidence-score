function [X_train, y_train, X_holdout, y_holdout, X_test, y_test] = loadDataset(dataset_path)
    training_file = dataset_path + "/training.csv";
    validation_file = dataset_path + "/validation.csv";
    test_file = dataset_path + "/test.csv";
    [X_train, y_train] = loadData2(training_file);
    [X_holdout, y_holdout] = loadData2(validation_file);
    [X_test, y_test] = loadData2(test_file);
end