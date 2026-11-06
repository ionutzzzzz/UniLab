function Sxy = cross_spectrum(x, y)
    % CROSS_SPECTRUM FFT(x) * conj(FFT(y))
    if nargin < 1, x = []; end
    if nargin < 2, y = []; end
    X = fft(x);
    Y = fft(y);
    Sxy = X .* conj(Y);
end
