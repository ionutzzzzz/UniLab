function [r] = snr(signal, noise)
    % SNR Signal-to-Noise Ratio in dB
    % r = snr(signal, noise) where noise can be the noise signal or its power
    
    p_signal = mean(signal.^2);
    if length(noise) == length(signal)
        p_noise = mean(noise.^2);
    else
        p_noise = noise;
    end
    
    r = 10 * log10(p_signal / p_noise);
end
