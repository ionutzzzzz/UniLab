function [call, put] = blkprice(F, K, T, r, sigma)
    % BLKPRICE Black's model for futures options
    d1 = (log(F / K) + (sigma^2 / 2) * T) / (sigma * sqrt(T));
    d2 = d1 - sigma * sqrt(T);
    df = exp(-r * T);
    call = df * (F * normcdf(d1) - K * normcdf(d2));
    put = df * (K * normcdf(-d2) - F * normcdf(-d1));
end
