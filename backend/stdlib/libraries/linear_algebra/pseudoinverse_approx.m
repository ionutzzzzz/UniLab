function A_pinv = pseudoinverse_approx(A)
    % PSEUDOINVERSE_APPROX Moore-Penrose pseudoinverse using SVD
    [U, S, V] = svd(A);
    s = diag(S);
    tol = max(size(A)) * eps(max(s));
    s_inv = zeros(size(s));
    idx = s > tol;
    s_inv(idx) = 1 ./ s(idx);
    S_inv = zeros(size(A'));
    for i = 1:length(s_inv)
        S_inv(i, i) = s_inv(i);
    end
    A_pinv = V * S_inv * U';
end
