function h = bandpass_filter_fir(N, f1, f2, fs)
    % BANDPASS_FILTER_FIR Design a simple FIR bandpass filter
    if nargin < 1, N = []; end
    if nargin < 2, f1 = []; end
    if nargin < 3, f2 = []; end
    if nargin < 4, fs = []; end
    lp2 = lowpass_filter_fir(N, f2, fs);
    lp1 = lowpass_filter_fir(N, f1, fs);
    h = lp2 - lp1;
end
