function F = magnetic_force(q, v, B, theta)
    F = q * v * B * sin(theta);
end