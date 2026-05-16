function [] = plot_matrix(M)
    % PLOT_MATRIX Visual representation of a matrix in terminal
    [r, c] = size(M);
    disp(['Matrix (', num2str(r), 'x', num2str(c), '):']);
    for i = 1:r
        row_str = '| ';
        for j = 1:c
            val = M(i, j);
            if val == 0
                char = ' . ';
            elseif val > 0
                char = ' + ';
            else
                char = ' - ';
            end
            row_str = [row_str, char];
        end
        disp([row_str, ' |']);
    end
end
