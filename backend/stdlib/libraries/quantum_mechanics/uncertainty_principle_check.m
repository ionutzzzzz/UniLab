function [sig_x, sig_p, check] = uncertainty_principle_check(psi, X, P, hbar)
    % UNCERTAINTY_PRINCIPLE_CHECK Verify sigma_x * sigma_p >= hbar/2
    if nargin < 4, hbar = 1; end
    
    ex = expectation_value_calc(psi, X);
    ex2 = expectation_value_calc(psi, X^2);
    sig_x = sqrt(real(ex2 - ex^2));
    
    ep = expectation_value_calc(psi, P);
    ep2 = expectation_value_calc(psi, P^2);
    sig_p = sqrt(real(ep2 - ep^2));
    
    check = (sig_x * sig_p >= (hbar / 2) - 1e-10);
end
