function [y] = butterworth_lowpass(x, fc, fs, n)
    % BUTTERWORTH_LOWPASS Simple numerical approximation of a Butterworth lowpass filter
    % This is a simplified frequency domain approach
    
    L = length(x);
    X = fft(x);
    f = (0:L-1) * (fs / L);
    
    % Transfer function: H(f) = 1 / sqrt(1 + (f/fc)^(2n))
    H = 1 ./ sqrt(1 + (f ./ fc).^(2 * n));
    
    % Apply filter
    Y = X .* H';
    y = real(ifft(Y));
end
