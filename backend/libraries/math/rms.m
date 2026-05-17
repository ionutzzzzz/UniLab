function [val] = rms(x)
    % RMS Root Mean Square value of a signal
    val = sqrt(mean(x.^2));
end
