function seq = collatz_sequence(n)
    % COLLATZ_SEQUENCE Generate the Collatz sequence starting from n
    if nargin < 1, n = []; end
    seq = [n];
    while n > 1
        if mod(n, 2) == 0
            n = n / 2;
        else
            n = 3 * n + 1;
        end
        seq = [seq, n];
    end
end
