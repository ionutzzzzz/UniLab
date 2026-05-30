function [w] = hanning_window(L)
    % HANNING_WINDOW Hanning window of length L
    % w(n) = 0.5 * (1 - cos(2*pi*n / (L-1)))
    
    n = 0:L-1;
    w = 0.5 * (1 - cos(2 * pi() * n ./ (L - 1)));
end
