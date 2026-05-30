function [sys] = zpk(z, p, k)
    sys = unilab_zpk(z, p, k);
end