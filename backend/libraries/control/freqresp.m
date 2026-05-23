function [w, h] = freqresp(sys, w)
    % FREQRESP Frequency response evaluation
    % [w, h] = freqresp(sys, w)
    if nargin < 2, w = []; end
    [w, h] = unilab_freqresp(sys, w);
end
