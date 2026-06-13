function dE_dt = heisenberg_uncertainty_e_t(hbar)
    if nargin < 1, hbar = []; end
    dE_dt = hbar / 2;
end
