function [z, p, k] = zpkdata(sys)
    % ZPKDATA Extract zero-pole-gain data
    % [z, p, k] = zpkdata(sys)
    [z, p, k] = unilab_zpkdata(sys);
end
