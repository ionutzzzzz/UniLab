function p = probLogit(X, beta)
    % PROBLOGIT Logistic regression probability
    z = X * beta;
    p = 1 ./ (1 + exp(-z));
end
