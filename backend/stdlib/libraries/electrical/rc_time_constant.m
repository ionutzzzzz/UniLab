function tau = rc_time_constant(R, C)
    if nargin < 1, R = []; end
    if nargin < 2, C = []; end
    tau = R * C;
end
