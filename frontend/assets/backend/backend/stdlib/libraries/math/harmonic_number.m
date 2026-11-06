function h = harmonic_number(n)
    % HARMONIC_NUMBER Calculate the n-th harmonic number Hn
    if nargin < 1, n = []; end
    h = sum(1 ./ (1:n));
end
