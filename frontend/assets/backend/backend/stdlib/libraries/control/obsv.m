function [O] = obsv(A, C)
    % OBSV Observability matrix
    % O = [C; CA; CA^2 ...]
    if nargin < 1, A = []; end
    if nargin < 2, C = []; end
    if nargin == 1 % obsv(sys)
        [A, ~, C, ~] = ssdata(A);
    end
    O = unilab_obsv(A, C);
end
