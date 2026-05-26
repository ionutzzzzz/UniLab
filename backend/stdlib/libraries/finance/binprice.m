function price = binprice(S, K, T, r, sigma, steps, type, american)
    % BINPRICE Option price using Cox-Ross-Rubinstein binomial model
    if nargin < 7, type = 'call'; end
    if nargin < 8, american = false; end
    
    dt = T / steps;
    u = exp(sigma * sqrt(dt));
    d = 1 / u;
    p = (exp(r * dt) - d) / (u - d);
    
    % Initialize asset prices at maturity
    S_at_T = zeros(steps + 1, 1);
    for i = 0:steps
        S_at_T(i + 1) = S * (u^i) * (d^(steps - i));
    end
    
    % Initialize option values at maturity
    V = zeros(steps + 1, 1);
    if strcmp(type, 'call')
        V = max(0, S_at_T - K);
    else
        V = max(0, K - S_at_T);
    end
    
    % Step back through the tree
    for j = steps-1:-1:0
        for i = 0:j
            V(i + 1) = exp(-r * dt) * (p * V(i + 2) + (1 - p) * V(i + 1));
            if american
                current_S = S * (u^i) * (d^(j - i));
                if strcmp(type, 'call')
                    V(i + 1) = max(V(i + 1), current_S - K);
                else
                    V(i + 1) = max(V(i + 1), K - current_S);
                end
            end
        end
    end
    price = V(1);
end
