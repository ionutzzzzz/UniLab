function nu = poisson_ratio(transverse_strain, axial_strain)
    if nargin < 1, transverse_strain = []; end
    if nargin < 2, axial_strain = []; end
    nu = -transverse_strain / axial_strain;
end
