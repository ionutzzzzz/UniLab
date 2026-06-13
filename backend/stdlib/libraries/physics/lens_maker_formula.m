function f = lens_maker_formula(n_lens, n_medium, R1, R2)
    % LENS_MAKER_FORMULA Calculate the focal length of a lens
    % f = lens_maker_formula(n_lens, n_medium, R1, R2)
    % R1, R2: radii of curvature of the two surfaces
    
    if nargin < 1, n_lens = []; end
    if nargin < 2, n_medium = []; end
    if nargin < 3, R1 = []; end
    if nargin < 4, R2 = []; end
    f = 1 / ((n_lens / n_medium - 1) * (1/R1 - 1/R2));
end
