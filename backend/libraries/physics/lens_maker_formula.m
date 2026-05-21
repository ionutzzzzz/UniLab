function f = lens_maker_formula(n_lens, n_medium, R1, R2)
    % LENS_MAKER_FORMULA Calculate the focal length of a lens
    % f = lens_maker_formula(n_lens, n_medium, R1, R2)
    % R1, R2: radii of curvature of the two surfaces
    
    f = 1 / ((n_lens / n_medium - 1) * (1/R1 - 1/R2));
end
