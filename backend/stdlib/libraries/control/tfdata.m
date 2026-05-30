function [num, den] = tfdata(sys)
    % TFDATA Extract numerator and denominator of a transfer function
    % [num, den] = tfdata(sys) returns the coefficients as cell arrays
    [num, den] = unilab_tfdata(sys);
end
