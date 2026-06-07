function model = gjr(p, q)
    % GJR Returns a GJR-GARCH model struct
    
    model.Type = 'GJR';
    model.P = p;
    model.Q = q;
    model.Constant = 0.001;
    model.GARCH = zeros(1, p);
    model.ARCH = zeros(1, q);
    model.Leverage = zeros(1, q);
end
