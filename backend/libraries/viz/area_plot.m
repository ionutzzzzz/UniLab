function [] = area_plot(x, y)
    % AREA_PLOT Create an ASCII area plot (filled under curve)
    if nargin < 2
        y = x;
        x = 1:length(y);
    end
    terminal_plot(y, x, 20, 60, 'area');
end
