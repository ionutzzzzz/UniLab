function [M] = blkdiag(varargin)
    % BLKDIAG Build block-diagonal matrix
    % M = blkdiag(A, B, ...)
    M = unilab_call(blkdiag, varargin{:});
end
