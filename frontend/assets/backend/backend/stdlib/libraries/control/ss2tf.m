function [num, den] = ss2tf(A, B, C, D, iu)
    if nargin < 1, A = []; end
    if nargin < 2, B = []; end
    if nargin < 3, C = []; end
    if nargin < 4, D = []; end
    if nargin < 5
        iu = 1; % MATLAB uses 1-based indexing for iu
    end
    % Convert to 0-based for Python
    [num, den] = unilab_ss2tf(A, B, C, D, iu - 1);
end