function C = bernoulli_equation_constant(P, rho, v, g, h)
    C = P + 0.5 * rho * v^2 + rho * g * h;
end
