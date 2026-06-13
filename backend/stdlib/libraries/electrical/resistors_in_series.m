function R_eq = resistors_in_series(R_array)
    if nargin < 1, R_array = []; end
    R_eq = sum(R_array);
end
