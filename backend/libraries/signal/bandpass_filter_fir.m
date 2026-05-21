function h = bandpass_filter_fir(N, f1, f2, fs)
    % BANDPASS_FILTER_FIR Design a simple FIR bandpass filter
    lp2 = lowpass_filter_fir(N, f2, fs);
    lp1 = lowpass_filter_fir(N, f1, fs);
    h = lp2 - lp1;
end
