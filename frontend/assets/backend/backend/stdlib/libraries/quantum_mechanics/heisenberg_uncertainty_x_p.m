function dx_dp = heisenberg_uncertainty_x_p(hbar)
    if nargin < 1, hbar = []; end
    dx_dp = hbar / 2;
end
