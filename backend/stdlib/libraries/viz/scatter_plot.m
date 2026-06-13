function scatter_plot(x, y, label)
    if nargin < 1, x = []; end
    if nargin < 2, y = []; end
    if nargin < 3, label = []; end
    scatter(x, y);
    if nargin > 2, title(label); end
end
