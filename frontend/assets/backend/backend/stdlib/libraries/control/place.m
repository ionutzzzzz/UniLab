function [K] = place(A, B, p)
    % PLACE Pole placement gain selection
    % K = place(A, B, p)
    if nargin < 1, A = []; end
    if nargin < 2, B = []; end
    if nargin < 3, p = []; end
    K = unilab_place(A, B, p);
end
