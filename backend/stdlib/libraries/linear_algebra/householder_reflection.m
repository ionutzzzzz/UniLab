function H = householder_reflection(v)
    % HOUSEHOLDER_REFLECTION Generate Householder matrix H = I - 2*v*v'/(v'*v)
    v = v(:);
    n = length(v);
    H = eye(n) - (2 * (v * v')) / (v' * v);
end
