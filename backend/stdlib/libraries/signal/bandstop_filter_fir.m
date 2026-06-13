function h = bandstop_filter_fir(N, f1, f2, fs)
    % BANDSTOP_FILTER_FIR Design a simple FIR bandstop filter
    if nargin < 1, N = []; end
    if nargin < 2, f1 = []; end
    if nargin < 3, f2 = []; end
    if nargin < 4, fs = []; end
    bp = bandpass_filter_fir(N, f1, f2, fs);
    h = -bp;
    h(floor(N/2) + 1) = h(floor(N/2) + 1) + 1;
end
