function [num, den] = tfdata(sys)
    % TFDATA Extract numerator and denominator of a transfer function
    % [num, den] = tfdata(sys) returns the coefficients as cell arrays
    if nargin < 1, sys = []; end
    [num, den] = unilab_tfdata(sys);
end
