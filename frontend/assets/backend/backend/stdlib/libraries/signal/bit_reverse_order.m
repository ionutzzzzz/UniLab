function idx = bit_reverse_order(n)
    % BIT_REVERSE_ORDER Return bit-reversed indices for length n=2^k
    if nargin < 1, n = []; end
    k = log2(n);
    idx = zeros(1, n);
    for i = 0:n-1
        b = dec2bin_custom(i, k);
        idx(i+1) = bin2dec_custom(b(end:-1:1)) + 1;
    end
end

function b = dec2bin_custom(d, n)
    if nargin < 1, d = []; end
    if nargin < 2, n = []; end
    b = '';
    for i = 1:n
        b = [num2str(mod(d, 2)), b];
        d = floor(d / 2);
    end
end

function d = bin2dec_custom(b)
    if nargin < 1, b = []; end
    d = 0;
    for i = 1:length(b)
        d = d + str2num(b(i)) * 2^(length(b)-i);
    end
end
