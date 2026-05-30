function x = kinematics_x(x0, v0, a, t)
    x = x0 + v0 * t + 0.5 * a * t^2;
end