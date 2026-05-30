function theta = subspace_angle(A, B)
    % SUBSPACE_ANGLE Smallest angle between two subspaces
    QA = orth_basis(A);
    QB = orth_basis(B);
    [~, S, ~] = svd(QA' * QB);
    theta = acos(max(min(diag(S)), 0));
end
