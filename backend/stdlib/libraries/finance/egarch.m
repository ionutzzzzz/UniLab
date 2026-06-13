function model = egarch(p, q)
    % EGARCH Returns an EGARCH model struct
    
    if nargin < 1, p = []; end
    if nargin < 2, q = []; end
    model.Type = 'EGARCH';
    model.P = p;
    model.Q = q;
    model.Constant = 0.001;
    model.GARCH = zeros(1, p);
    model.ARCH = zeros(1, q);
    model.Leverage = zeros(1, q);
end
