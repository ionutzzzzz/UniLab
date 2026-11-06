function model = garch(p, q)
    % GARCH Returns a GARCH model struct
    
    if nargin < 1, p = []; end
    if nargin < 2, q = []; end
    model.Type = 'GARCH';
    model.P = p;
    model.Q = q;
    model.Constant = 0.001;
    model.GARCH = zeros(1, p);
    model.ARCH = zeros(1, q);
end
