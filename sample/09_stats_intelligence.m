disp('📊 UniLab: Statistical Intelligence');
disp('==================================');

% 1. Descriptive Stats & Outliers
disp('--- 1. Distribution Analysis ---');
data = randn(100, 1) * 5 + 50; % Mean 50, Std 5
data(5) = 150; % Injected outlier

k = kurtosis(data);
s = skewness(data);
outliers = detect_outliers(data);

disp(['Kurtosis: ', num2str(k)]);
disp(['Skewness: ', num2str(s)]);
disp(['Detected ', num2str(sum(outliers)), ' anomalies.']);

% 2. Correlation & Regression
disp(' ');
disp('--- 2. Relationship Analysis ---');
X = rand(50, 2);
Y = 2*X(:,1) - 3*X(:,2) + 0.5*randn(50, 1);
C = correlation_matrix([X, Y]);
disp('Correlation Matrix (X1, X2, Y):');
disp(C);

% 3. Robust Scaling
disp(' ');
disp('--- 3. Data Cleaning ---');
scaler = robust_scaler(data);
disp('Data normalized using Interquartile Range.');

% 4. Bootstrap Estimation
disp(' ');
disp('--- 4. Confidence Intervals ---');
[means_dist, ci_low, ci_high] = bootstrap_mean(data, 1000);
disp(['95% CI for Mean: [', num2str(ci_low), ', ', num2str(ci_high), ']']);

disp(' ');
disp('Statistical Analysis Complete.');
