function F = coulombs_law(k, q1, q2, r)
    F = k * abs(q1 * q2) / r^2;
end