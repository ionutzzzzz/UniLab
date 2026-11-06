function [call, put] = blkprice(F, K, T, r, sigma)
    % BLKPRICE Black's model for futures options
    if nargin < 1, F = []; end
    if nargin < 2, K = []; end
    if nargin < 3, T = []; end
    if nargin < 4, r = []; end
    if nargin < 5, sigma = []; end
    d1 = (log(F / K) + (sigma^2 / 2) * T) / (sigma * sqrt(T));
    d2 = d1 - sigma * sqrt(T);
    df = exp(-r * T);
    call = df * (F * normcdf(d1) - K * normcdf(d2));
    put = df * (K * normcdf(-d2) - F * normcdf(-d1));
end
