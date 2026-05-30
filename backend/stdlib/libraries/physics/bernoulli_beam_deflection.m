function y = bernoulli_beam_deflection(P, L, E, I, x)
    % BERNOULLI_BEAM_DEFLECTION Deflection of a cantilever beam with point load at end
    % y = bernoulli_beam_deflection(P, L, E, I, x)
    % P: load, L: length, E: modulus, I: moment of inertia, x: position
    
    y = (P * x.^2) ./ (6 * E * I) .* (3 * L - x);
end
