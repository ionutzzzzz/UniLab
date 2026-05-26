function h = lowpass_filter_fir(N, fc, fs)
    % LOWPASS_FILTER_FIR Design a simple FIR lowpass filter using window method
    % N: filter order, fc: cutoff frequency, fs: sampling frequency
    n = -(N/2):(N/2);
    wc = 2 * pi() * fc / fs;
    h = sinc_custom(wc * n / pi()) .* (wc / pi());
    % Apply Hamming window
    w = hamming_window(N + 1);
    h = h .* w;
end
