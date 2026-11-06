function W = work_done(F, d, theta)
    if nargin < 1, F = []; end
    if nargin < 2, d = []; end
    if nargin < 3, theta = []; end
    W = F * d * cos(theta);
end
