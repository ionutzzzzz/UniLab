function M = markov(sys, N)
    if nargin < 1, sys = []; end
    if nargin < 2, N = []; end
    [A, B, C, D] = ssdata(ss(sys));
    
    M = zeros(1, N+1);
    M(1) = D;
    
    for k = 1:N
        M(k+1) = C * (A^(k-1)) * B;
    end
end