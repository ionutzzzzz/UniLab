function ev = expectation_value_calc(psi, Op)
    % EXPECTATION_VALUE_CALC <psi|Op|psi>
    if nargin < 1, psi = []; end
    if nargin < 2, Op = []; end
    ev = psi' * Op * psi;
end
