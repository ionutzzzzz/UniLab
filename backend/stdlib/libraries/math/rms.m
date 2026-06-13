function [val] = rms(x)
    % RMS Root Mean Square value of a signal
    if nargin < 1, x = []; end
    val = sqrt(mean(x.^2));
end
