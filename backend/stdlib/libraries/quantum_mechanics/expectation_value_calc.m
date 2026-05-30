function ev = expectation_value_calc(psi, Op)
    % EXPECTATION_VALUE_CALC <psi|Op|psi>
    ev = psi' * Op * psi;
end
