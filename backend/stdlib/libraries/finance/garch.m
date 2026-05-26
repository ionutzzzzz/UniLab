function model = garch(p, q)
    % GARCH Returns a GARCH model struct
    
    model.Type = 'GARCH';
    model.P = p;
    model.Q = q;
    model.Constant = 0.001;
    model.GARCH = zeros(1, p);
    model.ARCH = zeros(1, q);
end
