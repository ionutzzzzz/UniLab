function p = probLogit(X, beta)
    % PROBLOGIT Logistic regression probability
    if nargin < 1, X = []; end
    if nargin < 2, beta = []; end
    z = X * beta;
    p = 1 ./ (1 + exp(-z));
end
