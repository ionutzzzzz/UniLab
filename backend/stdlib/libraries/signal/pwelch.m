function [Pxx, f] = pwelch(x, fs)
    if nargin < 2, fs = 1.0; end
    [f, Pxx] = unilab_pwelch(x, fs);
end