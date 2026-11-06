function is_stable = state_space_stability(A)
    % STATE_SPACE_STABILITY Check stability of a state-space system
    % System is stable if all eigenvalues of A have negative real parts
    if nargin < 1, A = []; end
    e = eig(A);
    is_stable = all(real(e) < 0);
end
