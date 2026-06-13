function [C] = ctrb(A, B)
    % CTRB Controllability matrix
    % C = [B AB A^2B ...]
    if nargin < 1, A = []; end
    if nargin < 2, B = []; end
    if nargin == 1 % ctrb(sys)
        [A, B, ~, ~] = ssdata(A);
    end
    C = unilab_ctrb(A, B);
end
