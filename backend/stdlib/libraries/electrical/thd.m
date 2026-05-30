function [val] = thd(x, fs)
    % THD Calculates Total Harmonic Distortion of a signal
    % val = thd(x, fs)
    
    if nargin < 2, fs = 1; end
    
    X = fft(x);
    N = length(x);
    mag = abs(X(1:floor(N/2))) / (N/2);
    mag(1) = mag(1) / 2; % DC component
    
    % Find fundamental (max magnitude excluding DC)
    mag_subset = mag(2:end);
    [fund_mag, fund_idx] = max(mag_subset);
    fund_idx = fund_idx + 1;
    
    % Sum of squares of harmonics
    harmonics_ss = sum(mag(2:end).^2) - fund_mag^2;
    
    val = sqrt(harmonics_ss) / fund_mag;
end
