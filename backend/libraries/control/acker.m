function [K] = acker(A, B, p)
    % ACKER Pole placement for SISO systems using Ackermann's formula
    % K = acker(A, B, p)
    K = unilab_acker(A, B, p);
end
