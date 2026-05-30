function r = rand_gamma_custom(k, theta, n)
    if nargin < 3, n = 1; end
    % Simplified rejection sampling or use built-in if available
    r = zeros(n, 1);
    for i=1:n
        % Naive sum of exponentials if k is integer
        r(i) = sum(-log(rand(round(k), 1))) * theta;
    end
end