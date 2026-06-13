function r = roi(gain, cost)
    if nargin < 1, gain = []; end
    if nargin < 2, cost = []; end
    r = (gain - cost) / cost;
end