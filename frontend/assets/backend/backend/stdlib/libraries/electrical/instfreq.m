function [f] = instfreq(x, fs)
    % INSTFREQ Estimates instantaneous frequency
    % Uses the derivative of the phase of the analytic signal
    
    if nargin < 1, x = []; end
    if nargin < 2, fs = 1; end
    
    % Compute analytic signal via Hilbert transform (simplified FFT approach)
    N = length(x);
    X = fft(x);
    H = zeros(N, 1);
    if mod(N, 2) == 0
        H(1) = 1; H(N/2+1) = 1;
        H(2:N/2) = 2;
    else
        H(1) = 1;
        H(2:(N+1)/2) = 2;
    end
    z = ifft(X .* H);
    
    phi = unwrap(angle(z));
    f = diff_num(phi, 1/fs) / (2 * pi());
end
