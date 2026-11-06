function p = bra_ket_dot(bra, ket)
    % BRA_KET_DOT Inner product <bra|ket>
    if nargin < 1, bra = []; end
    if nargin < 2, ket = []; end
    p = (bra') * ket;
end
