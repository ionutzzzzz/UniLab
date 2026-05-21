function A = compound_interest(P, r, n, t)
    A = P * (1 + r/n)^(n*t);
end
