function G = givens_rotation(i, j, theta, n)
    % GIVENS_ROTATION Generate Givens rotation matrix
    if nargin < 1, i = []; end
    if nargin < 2, j = []; end
    if nargin < 3, theta = []; end
    if nargin < 4, n = []; end
    G = eye(n);
    c = cos(theta);
    s = sin(theta);
    G(i, i) = c;
    G(j, j) = c;
    G(i, j) = s;
    G(j, i) = -s;
end
