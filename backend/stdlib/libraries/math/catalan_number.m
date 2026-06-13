function c = catalan_number(n)
    % CATALAN_NUMBER Calculate the n-th Catalan number
    % C_n = (1 / (n + 1)) * (2n choose n)
    if nargin < 1, n = []; end
    c = nchoosek_custom(2*n, n) / (n + 1);
end
