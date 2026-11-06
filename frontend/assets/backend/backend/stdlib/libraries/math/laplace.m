function [F] = laplace(f, t, s)
    % LAPLACE Symbolic Laplace transform
    % F = laplace(f) computes the Laplace transform of f.
    % F = laplace(f, t, s) specifies the independent variable t and the transform variable s.
    
    if nargin < 1, f = []; end
    if nargin < 2, t = []; end
    if nargin < 3, s = []; end
    if nargin == 1
        F = unilab_laplace(f);
    elseif nargin == 2
        F = unilab_laplace(f, t);
    else
        F = unilab_laplace(f, t, s);
    end
end
