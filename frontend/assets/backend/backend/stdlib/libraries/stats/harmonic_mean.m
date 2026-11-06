function h = harmonic_mean(data)
    % HARMONIC_MEAN Harmonic mean of data
    if nargin < 1, data = []; end
    h = 1 / mean(1 ./ data);
end
