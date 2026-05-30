function h = harmonic_number(n)
    % HARMONIC_NUMBER Calculate the n-th harmonic number Hn
    h = sum(1 ./ (1:n));
end
