function [sv, w] = sigma(sys, w)
    % SIGMA Singular values of frequency response
    if nargin < 2, w = []; end
    [w, sv] = unilab_sigma(sys, w);
end
