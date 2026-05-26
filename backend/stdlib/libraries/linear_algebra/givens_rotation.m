function G = givens_rotation(i, j, theta, n)
    % GIVENS_ROTATION Generate Givens rotation matrix
    G = eye(n);
    c = cos(theta);
    s = sin(theta);
    G(i, i) = c;
    G(j, j) = c;
    G(i, j) = s;
    G(j, i) = -s;
end
