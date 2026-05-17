disp('--- 1. Testing Anonymous Functions ---');
sq = @(x) x.^2;
plus_ten = @(x, y) x + y + 10;
res1 = sq(5);
res2 = plus_ten(10, 20);
disp(['sq(5) = ', num2str(res1)]);
disp(['plus_ten(10, 20) = ', num2str(res2)]);

disp(' ');
disp('--- 2. Testing New Runtime Functions ---');
I = eye(3);
Z = zeros(2, 3);
O = ones(1, 4);
disp('eye(3):'); disp(I);
disp('zeros(2,3):'); disp(Z);
disp('ones(1,4):'); disp(O);
test_data = [10, 20, 30, 40, 50, 500];
m = median(test_data);
v = var(test_data);
q = quantile(test_data, 0.9);
disp(['Data: ', mat2str(test_data)]);
disp(['Median: ', num2str(m)]);
disp(['Variance: ', num2str(v)]);
disp(['90th Quantile: ', num2str(q)]);

disp(' ');
disp('--- 3. Testing Neural Network Visualization ---');
net_layers = [4 8 8 2];
disp(['Plotting NN with layers: ', mat2str(net_layers)]);
plot_nn(net_layers);
title('UniLab Neural Net Visualizer');

disp(' ');
disp('--- 4. Note on Data Export ---');
disp('New Feature: You can now export these variables to CSV or JSON');
disp('using the "Export Data..." button in the UniLab CLI app.');
disp('Done.');