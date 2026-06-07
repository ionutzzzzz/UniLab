function dS = entropy_change_ideal_gas(n, Cv, T1, T2, R, V1, V2)
    dS = n * Cv * log(T2/T1) + n * R * log(V2/V1);
end
