function [y] = butterworth_lowpass(x, fc, fs, n)
    % BUTTERWORTH_LOWPASS Simple numerical approximation of a Butterworth lowpass filter
    % This is a simplified frequency domain approach
    
    if nargin < 1, x = []; end
    if nargin < 2, fc = []; end
    if nargin < 3, fs = []; end
    if nargin < 4, n = []; end
    L = length(x);
    X = fft(x);
    f = (0:L-1) * (fs / L);
    
    % Transfer function: H(f) = 1 / sqrt(1 + (f/fc)^(2n))
    H = 1 ./ sqrt(1 + (f ./ fc).^(2 * n));
    
    % Apply filter
    Y = X .* H';
    y = real(ifft(Y));
end
