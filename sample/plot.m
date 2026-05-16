x = 0:0.5:10;
y = sin(x);
scatter_plot(x, y, 'Sine Wave');
data = randn(100, 1);
hist_plot(data, 12);
A = eye(5) - diag(ones(4,1), 1);
plot_matrix(A);