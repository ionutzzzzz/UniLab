function H = sys2hnn(sys, N)
    if nargin < 1, sys = []; end
    if nargin < 2, N = []; end
    [A, B, C, ~] = ssdata(ss(sys));
    
    num_params = 2 * N - 1;
    h = zeros(1, num_params);
    
    for k = 1:num_params
        h(k) = C * (A^(k-1)) * B;
    end

    col_1 = h(1:N);
    row_last = h(N:end);
    
    H = hankel(col_1, row_last);
end