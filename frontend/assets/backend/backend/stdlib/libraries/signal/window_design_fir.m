function h = window_design_fir(N, fc, fs, window_type)
    % WINDOW_DESIGN_FIR Design FIR filter with custom window
    if nargin < 1, N = []; end
    if nargin < 2, fc = []; end
    if nargin < 3, fs = []; end
    if nargin < 4, window_type = []; end
    n = -(N/2):(N/2);
    wc = 2 * pi() * fc / fs;
    h_ideal = sinc_custom(wc * n / pi()) .* (wc / pi());
    
    if strcmp(window_type, 'hamming')
        w = hamming_window(N + 1);
    elseif strcmp(window_type, 'hanning')
        w = hanning_window(N + 1);
    else
        w = ones(1, N + 1);
    end
    h = h_ideal .* w;
end
