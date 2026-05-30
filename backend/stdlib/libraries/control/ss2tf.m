function [num, den] = ss2tf(A, B, C, D, iu)
    if nargin < 5
        iu = 1; % MATLAB uses 1-based indexing for iu
    end
    % Convert to 0-based for Python
    [num, den] = unilab_ss2tf(A, B, C, D, iu - 1);
end