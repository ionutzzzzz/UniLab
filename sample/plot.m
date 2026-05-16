% test_viz.m - Test script for UniLab visualization functions

disp('=========================================');
disp('   UniLab Visualization Library Test     ');
disp('=========================================');

% 1. area_plot
disp(' ');
disp('--- 1. Testing area_plot ---');
x_area = 0:0.5:10;
y_area = abs(sin(x_area));
area_plot(x_area, y_area);

% 2. bar_plot
disp(' ');
disp('--- 2. Testing bar_plot ---');
y_bar = [5, 12, 8, 15, 7];
labels_bar = {'A', 'B', 'C', 'D', 'E'};
bar_plot(y_bar, labels_bar);

% 3. box_plot
disp(' ');
disp('--- 3. Testing box_plot ---');
data_box = randn(50, 1) * 10 + 50;
box_plot(data_box);

% 4. heatmap
disp(' ');
disp('--- 4. Testing heatmap ---');
M_heatmap = [1 2 3; 4 5 6; 7 8 9];
heatmap(M_heatmap);

% 5. hist_plot
disp(' ');
disp('--- 5. Testing hist_plot ---');
data_hist = randn(100, 1);
hist_plot(data_hist, 10);

% 6. plot_matrix
disp(' ');
disp('--- 6. Testing plot_matrix ---');
M_plot = eye(5) + diag(ones(4,1), 1) - diag(ones(4,1), -1);
plot_matrix(M_plot);

% 7. scatter_plot
disp(' ');
disp('--- 7. Testing scatter_plot ---');
x_scatter = 1:10;
y_scatter = x_scatter + randn(1, 10);
scatter_plot(x_scatter, y_scatter, 'Noisy Line');

% 8. stairs_plot
disp(' ');
disp('--- 8. Testing stairs_plot ---');
y_stairs = [1, 2, 2, 3, 1, 0, 1];
stairs_plot(y_stairs);

% 9. stem_plot
disp(' ');
disp('--- 9. Testing stem_plot ---');
y_stem = sin(0:0.5:5);
stem_plot(y_stem);

% 10. terminal_heatmap
disp(' ');
disp('--- 10. Testing terminal_heatmap ---');
M_term_heat = rand(10, 10);
terminal_heatmap(M_term_heat, 10, 30);

% 11. terminal_plot
disp(' ');
disp('--- 11. Testing terminal_plot ---');
y_term = cos(0:0.5:10);
terminal_plot(y_term);

disp(' ');
disp('=========================================');
disp('   Visualization Test Complete           ');
disp('=========================================');
