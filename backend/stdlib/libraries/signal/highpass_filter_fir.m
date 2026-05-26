function h = highpass_filter_fir(N, fc, fs)
    % HIGHPASS_FILTER_FIR Design a simple FIR highpass filter
    lp = lowpass_filter_fir(N, fc, fs);
    h = -lp;
    h(floor(N/2) + 1) = h(floor(N/2) + 1) + 1;
end
