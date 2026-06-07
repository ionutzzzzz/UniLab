function [w] = hamming_window(L)
    % HAMMING_WINDOW Hamming window of length L
    % w(n) = 0.54 - 0.46 * cos(2*pi*n / (L-1))
    
    n = 0:L-1;
    w = 0.54 - 0.46 * cos(2 * pi() * n ./ (L - 1));
end
