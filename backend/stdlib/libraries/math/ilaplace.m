function [f] = ilaplace(F, s, t)
    % ILAPLACE Symbolic inverse Laplace transform
    % f = ilaplace(F) computes the inverse Laplace transform of F.
    % f = ilaplace(F, s, t) specifies the transform variable s and the independent variable t.
    
    if nargin < 1, F = []; end
    if nargin < 2, s = []; end
    if nargin < 3, t = []; end
    if nargin == 1
        f = unilab_ilaplace(F);
    elseif nargin == 2
        f = unilab_ilaplace(F, s);
    else
        f = unilab_ilaplace(F, s, t);
    end
end
