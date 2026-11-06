function z = redshift(lambda_obs, lambda_rest)
    if nargin < 1, lambda_obs = []; end
    if nargin < 2, lambda_rest = []; end
    z = (lambda_obs - lambda_rest) / lambda_rest;
end
