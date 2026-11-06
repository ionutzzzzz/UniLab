function C_eq = capacitors_in_series(C_array)
    if nargin < 1, C_array = []; end
    C_eq = 1 / sum(1 ./ C_array);
end
