function W = isothermal_work(n, R, T, V1, V2)
    W = n * R * T * log(V2 / V1);
end
